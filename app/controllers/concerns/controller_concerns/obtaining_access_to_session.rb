# frozen_string_literal: true

module ControllerConcerns::ObtainingAccessToSession
  extend ActiveSupport::Concern
  include SessionsHelper
  included do
    before_action :load_session, only: %i[preview_purchase confirm_purchase paypal_purchase confirm_paypal_purchase]
    before_action :sanitize_purchase_type,
                  only: %i[preview_purchase confirm_purchase paypal_purchase confirm_paypal_purchase]
  end

  private def load_session
    value = params[:session_slug] || params[:id]

    @session = Session.where('id = ? OR slug = ?', value.to_immerss_i, value).last!
  end

  def preview_purchase
    if current_user.email.blank?
      flash[:error] = 'Please provide email'
      respond_to do |format|
        format.js { render js: "window.eventHub.$emit('open-modal:auth', 'more-info')" }
        format.html { redirect_to edit_application_profile_path }
      end
      return
    end
    if @session.finished? && @type != ObtainTypes::FREE_VOD && @type != ObtainTypes::PAID_VOD
      flash[:error] = 'Session is already over'
      return redirect_back fallback_location: root_path
    end

    if @session.cancelled?
      flash[:error] = I18n.t('mailer.session_cancelled_body_prefix', url: @session.absolute_path,
                                                                     title: @session.always_present_title,
                                                                     cancel_reason: @session.abstract_session_cancel_reason.name).html_safe
      return redirect_back fallback_location: root_path
    end

    if params[:type].include?('paid') && cannot?(:monetize_content_by_business_plan, @session.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return redirect_back fallback_location: root_path
    end

    interactor1 = ObtainImmersiveAccessToSession.new(@session, current_user)
    interactor2 = ObtainLivestreamAccessToSession.new(@session, current_user)
    interactor3 = ObtainRecordedAccessToSession.new(@session, current_user)
    if params[:type] == ObtainTypes::FREE_IMMERSIVE && (interactor1.can_have_free_trial? || interactor1.can_take_for_free?)
      obtain_free_immersive_access

      _redirect_path = if request.env['HTTP_REFERER'].include?(@session.channel.slug)
                         "#{@session.absolute_path}?subscribe=free_immersive"
                       else
                         @session.relative_path || request.referer || root_path
                       end

      respond_to do |format|
        format.html { redirect_to @session.relative_path }
        format.js { render js: "window.location = #{_redirect_path.to_json}" }
      end
      return
    elsif params[:type] == ObtainTypes::FREE_LIVESTREAM && (interactor2.can_have_free_trial? || interactor2.can_take_for_free?)
      obtain_free_livestream_access

      _redirect_path = if request.env['HTTP_REFERER'].include?(@session.channel.slug)
                         "#{@session.absolute_path}?subscribe=free_livestream"
                       else
                         @session.absolute_path || request.referer || root_path
                       end

      respond_to do |format|
        format.html { redirect_to @session.relative_path }
        format.js { render js: "window.location = #{_redirect_path.to_json}" }
      end
      return
    elsif params[:type] == ObtainTypes::FREE_VOD && interactor3.can_take_for_free?
      obtain_free_recorded_access
      flash[:success] = I18n.t('thank_yous.obtained_session_success_message')
      _redirect_path = "#{@session.relative_path}#{video_anchor(@session)}"

      respond_to do |format|
        format.html { redirect_to _redirect_path }
        format.js { render js: "window.location = #{_redirect_path.to_json}" }
      end
      return
    end
    if [ObtainTypes::PAID_IMMERSIVE, ObtainTypes::PAID_LIVESTREAM].include?(params[:type])
      @another_session = current_user.participate_between(@session.start_at, @session.end_at).first
    end
    # fix IMD-547,IMD-558
    if [ObtainTypes::PAID_IMMERSIVE,
        ObtainTypes::FREE_IMMERSIVE].include?(params[:type]) && interactor1.could_be_obtained?
      # do nothing
    elsif [ObtainTypes::PAID_LIVESTREAM,
           ObtainTypes::FREE_LIVESTREAM].include?(params[:type]) && interactor2.could_be_obtained?
      # do nothing
    elsif params[:type] == ObtainTypes::PAID_VOD && interactor3.could_be_obtained?
      # do nothing
    else
      flash[:success] = "Can not interpret, #{params[:type]}"
      _redirect_path = "#{@session.relative_path}#{video_anchor(@session)}"

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
        redirect_to "#{@session.relative_path}?#{{ autodisplay_remote_ujs_path: request.original_fullpath }.to_param}"
      end
      format.js { render "sessions/#{__method__}" }
    end
  end

  def paypal_execute_payment
    if Orders::Paypal.execute_payment(payment_id: params[:paymentID], payer_id: params[:payerID])
      render json: {}, status: 200
    else
      render json: { error: 'Oops something went wrong. Please call the administrator' }, status: 422
    end
  end

  def paypal_purchase
    if cannot?(:monetize_content_by_business_plan, @session.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return redirect_to @session.relative_path
    end

    if @session.payment_transactions.not_archived.not_failed.exists?(user: current_user)
      flash[:info] = 'Session already purchased'
      return redirect_to @session.relative_path
    end

    price = nil
    case @type
    when ObtainTypes::PAID_IMMERSIVE
      price = @session.immersive_purchase_price
    when ObtainTypes::PAID_LIVESTREAM
      price = @session.livestream_purchase_price
    when ObtainTypes::PAID_VOD
      price = @session.recorded_purchase_price
    when ObtainTypes::FREE_IMMERSIVE
      obtain_free_immersive_access
    when ObtainTypes::FREE_LIVESTREAM
      obtain_free_livestream_access
    end
    if price
      @discount_amount = 0.0
      if params[:discount]
        @discount = Discount.find_by(name: params[:discount])
        @discount_amount = if @discount&.valid_for?(@session, params[:obtain_type], current_user)
                             if @discount.amount_off_cents
                               (price - (@discount.amount_off_cents.to_f / 100)).round(2)
                             else
                               (price / 100 * @discount.percent_off_precise).round(2)
                             end
                           else
                             0.0
                           end
      end
      price -= @discount_amount
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
                  name: @session.title,
                  sku: @session.title,
                  price: price,
                  currency: currency,
                  quantity: 1
                }]
              },
              amount: {
                total: price,
                currency: currency
              },
              description: "Payment for: #{@session.title}"
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
      redirect_to @session.relative_path
    end
  end

  def confirm_paypal_purchase
    # {"paymentID"=>"PAYID-MKLVVZY4KX85026W4755874T", "payerID"=>"XFR9XTYVX9EXJ", "provider"=>"paypal", "amp"=>nil, "type"=>"paid_livestream", "user_id"=>"297", "discount"=>"", "controller"=>"sessions", "action"=>"confirm_paypal_purchase", "channel_id"=>"64", "id"=>"296"}
    # raise 'not authorized' if env['HTTP_ORIGIN'] != 'https://www.sandbox.paypal.com' || env['HTTP_ORIGIN'] != 'https://www.sandbox.paypal.com' || env['HTTP_ORIGIN'] != 'https://www.paypal.com'
    transaction = @session.payment_transactions.not_archived.not_failed.find_or_initialize_by(provider: :paypal,
                                                                                              user_id: params[:user_id] || current_user.id)
    if transaction.persisted?
      flash[:info] = 'Session already purchased'
      redirect_to @session.relative_path
    else
      case @type
      when ObtainTypes::PAID_IMMERSIVE
        confirm_immersive_purchase
      when ObtainTypes::PAID_LIVESTREAM
        confirm_livestream_purchase
      when ObtainTypes::PAID_VOD
        confirm_recorded_purchase
      end
      redirect_to @session.relative_path
    end
  end

  def confirm_purchase
    case @type
    when ObtainTypes::PAID_IMMERSIVE
      confirm_immersive_purchase
    when ObtainTypes::FREE_IMMERSIVE
      obtain_free_immersive_access
    end

    case @type
    when ObtainTypes::PAID_LIVESTREAM
      confirm_livestream_purchase
    when ObtainTypes::FREE_LIVESTREAM
      obtain_free_livestream_access
    end

    if @type == ObtainTypes::PAID_VOD
      confirm_recorded_purchase
    end

    if flash.to_hash.keys.detect { |key| key.start_with?('error') }
      # flash
      #=> #<ActionDispatch::Flash::FlashHash:0x007fc482dab008 @discard=#<Set: {}>, @flashes={"error" => "Cannot use a payment_method_nonce more than once."}, @now=nil>
      # TODO - catch and replace this message with a more user-friendly one?

      if @type == ObtainTypes::PAID_VOD
        return redirect_to "#{@session.relative_path}#{video_anchor(@session)}"
      end

      redirect_to preview_purchase_channel_session_path(@session.slug, type: @type)
    else
      @session.unchain_all!
      if @type == ObtainTypes::PAID_VOD
        flash[:success] = I18n.t('thank_yous.obtained_session_success_message')
        return redirect_to "#{@session.relative_path}#{video_anchor(@session)}"
      end
      redirect_to @session.relative_path
    end
  end

  private

  def sanitize_purchase_type
    @type = params[:type]
    if @type.blank? || ObtainTypes::ALL.exclude?(@type)
      notify_airbrake(RuntimeError.new("?type was lost somewhere on #{action_name}}"),
                      parameters: {
                        current_user_id: current_user.try(:id),
                        type: @type
                      })

      flash[:notice] = 'Purchase attempt failed. Please try again.'
      redirect_to @session.relative_path
    end
  end

  def obtain_free_immersive_access
    interactor = ObtainImmersiveAccessToSession.new(@session, current_user)
    interactor.free_type_is_chosen!
    interactor.execute
    current_user.touch
    if interactor.error_message
      flash[:error1] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success1] = interactor.success_message
      Rails.logger.info logger_user_tag + "user has obtained free immersive access to session #{@session.always_present_title}"
    end
  end

  def obtain_free_livestream_access
    interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
    interactor.free_type_is_chosen!
    interactor.execute
    current_user.touch
    if interactor.error_message
      flash[:error2] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success2] = interactor.success_message
      Rails.logger.info logger_user_tag + "user has obtained free livestream access to session #{@session.always_present_title}"
    end
  end

  def obtain_free_recorded_access
    interactor = ObtainRecordedAccessToSession.new(@session, current_user)
    interactor.free_type_is_chosen!
    interactor.execute
    current_user.touch
    if interactor.error_message
      flash[:error1] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success1] = interactor.success_message
      Rails.logger.info logger_user_tag + "user has obtained free recorded access to session #{@session.always_present_title}"
    end
  end

  def confirm_immersive_purchase
    if cannot?(:monetize_content_by_business_plan, @session.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return
    end
    interactor = ObtainImmersiveAccessToSession.new(@session, current_user)
    interactor.paid_type_is_chosen!
    interactor.execute(params)
    current_user.touch
    if interactor.error_message
      flash[:error3] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success3] = interactor.success_message
    end
  end

  def confirm_livestream_purchase
    if cannot?(:monetize_content_by_business_plan, @session.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return
    end
    interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
    interactor.paid_type_is_chosen!
    interactor.execute(params)
    current_user.touch
    if interactor.error_message
      flash[:error4] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success4] = interactor.success_message
    end
  end

  def confirm_recorded_purchase
    if cannot?(:monetize_content_by_business_plan, @session.channel.organization)
      flash[:error] = 'Payments are not allowed'
      return
    end
    interactor = ObtainRecordedAccessToSession.new(@session, current_user)
    interactor.execute(params)
    current_user.touch
    if interactor.error_message
      flash[:error5] = interactor.error_message.html_safe
      Rails.logger.debug interactor.error_message.inspect
    else
      flash[:success5] = interactor.success_message
    end
  end
end
