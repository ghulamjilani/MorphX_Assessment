# frozen_string_literal: true

module ControllerConcerns::ObtainingAccessToRecording
  extend ActiveSupport::Concern

  included do
    before_action :sanitize_purchase_type,
                  only: %i[preview_purchase confirm_purchase paypal_purchase confirm_paypal_purchase]
  end

  def preview_purchase
    if cannot?(:monetize_content_by_business_plan, @recording.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return redirect_back fallback_location: root_path
    end

    if current_user.email.blank?
      flash[:error] = 'Please provide email'
      respond_to do |format|
        format.js { render js: "window.eventHub.$emit('open-modal:auth', 'more-info')" }
        format.html { redirect_to edit_application_profile_path }
      end
      return
    end
    interactor = ObtainAccessToRecording.new(@recording, current_user)

    if params[:type] == ObtainTypes::FREE_RECORDING && interactor.can_take_for_free?
      obtain_free_recording_access
      flash[:success] = I18n.t('thank_yous.obtained_session_success_message')
      _redirect_path = "#{@recording.relative_path}#{recording_anchor(@recording.id)}"

      respond_to do |format|
        format.html { redirect_to _redirect_path }
        format.js { render js: "window.location = #{_redirect_path.to_json}" }
      end
      return
    end

    # invited co-presenter is allowed to pay with system credit, just like any other user
    gon.system_credit_balance = current_user.system_credit_balance.to_f

    # generate_client_token

    respond_to do |format|
      format.html do
        redirect_to "#{@recording.relative_path}&#{{ autodisplay_remote_ujs_path: request.original_fullpath }.to_param}"
      end
      format.js { render "recordings/#{__method__}" }
    end
  end

  def confirm_purchase
    case @type
    when ObtainTypes::PAID_RECORDING
      confirm_recording_purchase
    when ObtainTypes::FREE_RECORDING
      obtain_free_recording_access
    end

    if flash.to_hash.key?('error')
      # flash
      #=> #<ActionDispatch::Flash::FlashHash:0x007fc482dab008 @discard=#<Set: {}>, @flashes={"error" => "Cannot use a payment_method_nonce more than once."}, @now=nil>
      # TODO - catch and replace this message with a more user-friendly one?

      redirect_to preview_purchase_recording_path(@recording, type: @type)
    else
      flash[:success] = I18n.t('thank_yous.obtained_session_success_message') if @type == ObtainTypes::PAID_RECORDING
      redirect_to @recording.absolute_path, allow_other_host: true
    end
  end

  def paypal_purchase
    if cannot?(:monetize_content_by_business_plan, @recording.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return redirect_to @recording.relative_path
    end

    if @recording.payment_transactions.not_archived.not_failed.exists?(user: current_user)
      flash[:info] = 'Recording already purchased'
      return redirect_to @recording.relative_path
    end

    price = nil
    case @type
    when ObtainTypes::PAID_RECORDING
      price = @recording.purchase_price.to_f
    when ObtainTypes::FREE_RECORDING
      obtain_free_recording_access
    end
    if price
      @tax = 0
      currency = 'USD'
      payment = PayPal::SDK::REST::Payment.new(
        {
          intent: 'sale',
          payer: {
            payment_method: 'paypal'
          },
          redirect_urls: {
            return_url: '/',
            cancel_url: '/'
          },
          transactions: [
            {
              item_list: {
                items: [{
                  name: @recording.title,
                  sku: @recording.title,
                  price: price,
                  currency: currency,
                  quantity: 1
                }]
              },
              amount: {
                total: price,
                currency: currency
              },
              description: "Payment for: #{@recording.title}"
            }
          ]
        }
      )
      begin
        if payment.create
          render json: { token: payment.token }, status: 200
        else
          render json: { error: I18n.t('errors.messages.something_went_wrong') }, status: 422
        end
      rescue StandardError => e
        render json: { error: e.message }, status: 422
      end
    else
      redirect_to @recording.relative_path
    end
  end

  def confirm_paypal_purchase
    # "{"provider"=>"paypal", "type"=>"paid_immersive", "user_id"=>"4", "amt"=>"28.20", "cc"=>"USD", "item_name"=>"Brainsphere The Fortress of Solitude 68", "item_number"=>"26", "st"=>"Completed", "tx"=>"76637784XE524333H", "controller"=>"sessions", "action"=>"confirm_paypal_purchase", "channel_id"=>"10", "id"=>"26"}"
    # raise 'not authorized' if env['HTTP_ORIGIN'] != 'https://www.sandbox.paypal.com' || env['HTTP_ORIGIN'] != 'https://www.sandbox.paypal.com' || env['HTTP_ORIGIN'] != 'https://www.paypal.com'
    transaction = @recording.payment_transactions.not_archived.not_failed.find_or_initialize_by(provider: :paypal,
                                                                                                user_id: params[:user_id] || current_user.id)
    if transaction.persisted?
      flash[:info] = 'Recording already purchased'
      redirect_to @recording.relative_path
    else
      if @type == ObtainTypes::PAID_RECORDING
        confirm_recording_purchase
      end
      redirect_to @recording.relative_path
    end
  end

  private

  def sanitize_purchase_type
    @type = params[:type]
    if @type.blank? || ObtainTypes::ALL.exclude?(@type)
      notify_airbrake(RuntimeError.new("?type was lost somewhere on #{action_name}}"),
                      parameters: {
                        current_user_id: current_user.id,
                        type: @type
                      })

      flash[:notice] = 'Purchase attempt failed. Please try again.'
      redirect_to @recording.relative_path
    end
  end

  def obtain_free_recording_access
    interactor = ObtainAccessToRecording.new(@recording, current_user)
    interactor.free_type_is_chosen!
    interactor.execute
    if interactor.error_message
      flash[:error] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success] = interactor.success_message
      Rails.logger.info logger_user_tag + "user has obtained free access to recording #{@recording.always_present_title}"
    end
  end

  def confirm_recording_purchase
    if cannot?(:monetize_content_by_business_plan, @recording.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return
    end
    interactor = ObtainAccessToRecording.new(@recording, current_user)
    interactor.execute(params)
    if interactor.error_message
      flash[:error] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success] = interactor.success_message
    end
  end
end
