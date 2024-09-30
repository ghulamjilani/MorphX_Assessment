# frozen_string_literal: true

class ProfilesController < Dashboard::ApplicationController
  def time_format
    current_user.time_format = params[:time_format]
    if current_user.save
      head :ok
    else
      flash[:error] = current_user.errors.full_messages.join('. ')
      redirect_back fallback_location: root_path
    end
  end

  # Parameters: {"phone"=>"+380683728661", "_"=>"1473100074115"}
  def preview_phone_number_verification_modal
    @sent_to_phone_number = PhonyRails.normalize_number(params[:phone]).phony_formatted(format: :international)

    initiate_verification_sms @sent_to_phone_number

    respond_to do |format|
      format.js { render "profiles/#{__method__}" }
    end
  end

  def initiate_verification_sms(number)
    unless Phony.plausible?(number)
      flash.now[:error] = 'Please provide a valid phone number'

      @success = false
      return
    end

    normalized   = Phony.normalize(number)
    splitted     = Phony.split(normalized)
    #=> "380"
    country_code = splitted.first
    #=> "683728661"
    cellphone    = splitted[1..].join('')

    # TODO: - what if there is already an existing user?
    authy = Authy::API.register_user(
      email: current_user.email,
      cellphone: cellphone,
      country_code: country_code,
      send_install_link_via_sms: false
    )

    if authy.success?
      authy_record = current_user.authy_records.create!(authy_user_id: authy.id,
                                                        cellphone: cellphone,
                                                        country_code: country_code)

      result = Authy::API.request_sms(id: authy.id, locale: 'en')

      # Cookie#domain returns dot-less domain name now. Use Cookie#dot_domain if you need "." at the beginning.
      #=> {"success"=>true, "message"=>"SMS token was sent", "cellphone"=>"+380-XX1126326"}
      # result.success?
      # result.message
      # result.cellphone
      # > authy.id
      #=> 22850748
      if result.success?
        authy_record.update_attribute(:status, AuthyRecord::Statuses::SENT)
        @success = true
      else
        flash.now[:error] = result.message
        @success = false
      end
    else
      Rails.logger.info authy.errors.inspect
      authy.errors.reject { |k, _v| k == 'message' }.collect { |k, v| "#{k} #{v}" }.each do |str|
        flash.now[:error] = str
      end

      @success = false
    end
  end

  def verify_phone_number
    authy_record = current_user.authy_records.last

    token = Authy::API.verify(id: authy_record.authy_user_id, token: params[:code])

    if token.success?
      @success = true
      @success_message = 'Your phone number has just been confirmed'
      authy_record.update_attribute(:status, AuthyRecord::Statuses::APPROVED)
    else
      @success = false
      flash.now[:error] = 'Invalid code'
    end

    respond_to do |format|
      format.js { render "profiles/#{__method__}" }
    end
  end

  def disconnect_social_account
    if params[:provider] == 'zoom'
      connected_zoom_account = current_user.zoom_identity
      if connected_zoom_account.present?
        begin
          sender = Sender::ZoomLib.new(identity: connected_zoom_account)
          sender.revoke_token
        rescue StandardError => e
          puts e
        end
      end
    end
    current_user.identities.where(provider: params[:provider]).destroy_all

    redirect_back fallback_location: root_path
  end

  def edit_preferences
    current_user.user_account || current_user.build_user_account
  end

  def edit_billing
    @sources = current_user.stripe_customer_sources
    gon.stripe_key = Rails.application.credentials.global.dig(:stripe, :public_key)
  end

  def donations
  end

  def edit_general
    if current_user.user_account.blank?
      record = IpInfoRecord.where(ip: request.remote_ip).last

      country = if record.present?
                  record.country
                else
                  'US'
                end

      current_user.build_user_account(country: country)
    end
  end

  def edit_application
    @user = User.find current_user.id
  end

  def edit_notifications
    @notification_settings = ModelConcerns::Settings::Notification.initialize_from_scoped_settings(current_user)
    @combined_settings     = CombinedNotificationSetting.notification_settings_for(current_user)
  end

  def edit_public
    current_user.user_account || current_user.build_user_account

    prepare_soc_links
  end

  def stream_options
  end

  def download_client
  end

  def update
    # TODO: review this spaghetti of conditions
    if notification_attributes.present?
      update_notifications
    else
      raise "unknown type of request. req params: #{params}"
    end
    flash[:success] ||= I18n.t('controllers.profiles.update_success')
  end

  # return [Boolean]
  private def update_almost_done
    if params[:user][:email].present?
      current_user.email = params[:user][:email]
    end
    if params[:user][:password].present?
      current_user.password = params[:user][:password]
    end
    birthdate_attributes = params[:user].permit('birthdate(2i)', 'birthdate(3i)', 'birthdate(1i)')
    if birthdate_attributes.present?
      current_user.attributes = birthdate_attributes
    end
    current_user.skip_validation_for :gender
    current_user.skip_validation_for :first_name
    current_user.skip_validation_for :last_name

    current_user.save
  end

  def update_general
    if update_almost_done_request?
      result = update_almost_done
      Rails.logger.debug current_user.errors.full_messages unless result
      respond_to do |format|
        format.json { render 'update_almost_done', locals: { user: current_user }, status: result ? 201 : 400 }
        format.js { head :ok }
      end
      return
    end

    current_user.attributes = profile_attributes

    if current_user.save
      # because if email was blank during creation(twitter) - email is not sent from Devise
      # (after_create  :send_on_create_confirmation_instructions, if: :send_confirmation_notification?)
      # after_update  :send_reconfirmation_instructions,  if: :reconfirmation_required? is not triggered either because #email could be still blank
      current_user.send(:pending_any_confirmation) do
        current_user.send_confirmation_instructions
      end

      flash[:success] = I18n.t('controllers.profiles.update_success')
      redirect_to action: 'edit_general'
    else
      # catching it manually because with new :image update mechanism that err message
      # wouldn't be visible anywhere otherwise
      messages = current_user.user_account.errors.full_messages
      if messages.any? { |message| message.include?(I18n.t('errors.messages.rmagick_processing_error')) }
        flash.now[:error] = I18n.t('errors.messages.rmagick_processing_error')
      elsif messages.size == 1 && messages.first.start_with?('Image Image') # avatar updating mechanism(triggered from left sidebar upload)
        flash.now[:error] = messages.first.gsub('Image Image', 'Image')
      elsif messages.size == 1 && messages.first.start_with?('Image You') # like "Image You are not allowed to upload \"pdf\" files, allowed types: jpg, jpeg, png, bmp"
        flash.now[:error] = messages.first.gsub('Image You', 'You')
      end

      Rails.logger.debug current_user.errors.full_messages.inspect
      render 'edit_general'
    end
  end

  def update_settings
    result = current_user.update(profile_attributes)

    if result
      flash[:success] = 'Your account has been successfully updated'
      redirect_to action: 'edit_preferences'
    else
      render 'edit_preferences'
    end
  end

  def update_public
    current_user.attributes = profile_attributes
    current_user.account.validate_public_info = true

    if current_user.save
      flash[:success] = 'Your public account has been successfully updated'
      redirect_to action: 'edit_public'
    else
      flash[:error] = current_user.errors.full_messages.join('. ')
      prepare_soc_links
      render 'edit_public'
    end
  end

  def update_donations
    current_user.attributes = profile_attributes

    if current_user.save
      flash[:success] = 'Your Donations URL has been successfully updated'
      redirect_to action: 'donations'
    else
      flash[:error] = current_user.errors.full_messages.join('. ')
      render 'donations'
    end
  end

  def update_application
    @user = User.find current_user.id
    has_password = profile_attributes.slice(:password, :password_confirmation, :current_password).select do |_k, v|
      v.present?
    end.present?

    if has_password
      if current_ability.can?(:change_password, current_user)
        result = @user.update_with_password(profile_attributes.slice(:password, :password_confirmation,
                                                                     :current_password))
      else
        @user.skip_validation_for(*all_validation_skipable_user_attributes.dup.reject { |s| s == :email })
        result = @user.update(profile_attributes.slice(:password, :password_confirmation, :current_password))
      end
    else
      unless (result = @user.update(profile_attributes.slice(:email)))
        flash[:error] = @user.full_errors
      end
    end

    if result
      sign_in(:user, @user, bypass: true) if has_password
      flash[:success] = 'Your account has been successfully updated'
    else
      flash[:error] = I18n.t('controllers.profiles.update_passwor_error')
    end

    redirect_to action: 'edit_application'
  end

  def destroy
    if current_user.channels_subscriptions.where(canceled_at: nil).count.positive?
      flash[:error] = I18n.t('controllers.profiles.destroy.active_channel_subscriptions')
      redirect_to my_subscriptions_dashboard_money_index_path
    elsif current_user.service_subscription.present?
      flash[:error] = I18n.t('controllers.profiles.destroy.active_business_subscriptions')
      redirect_to spa_dashboard_business_plan_index_path
    else
      current_user.mark_as_destroyed
      sign_out
      flash[:success] = I18n.t('controllers.profiles.destroy.success')
      redirect_to root_path
    end
  end

  def save_cover
    cover_params = params.require(:user_account).permit(:crop_x, :crop_y, :crop_w, :crop_h, :rotate, :original_bg_image)
    @interactor = SaveUserCover.new(current_user, cover_params)
    if @interactor.execute
      render json: { bg_image_url: @interactor.user_account.bg_image_url }
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  def save_logo
    logo_params = params.require(:user_account).permit(logo: %i[crop_x crop_y crop_w crop_h rotate original_image])
    @interactor = SaveUserLogo.new(current_user, logo_params)
    if @interactor.execute
      render json: { logo: @interactor.logo.medium_avatar_url }
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  private

  def update_almost_done_request?
    params[:user].present?
  end

  def update_notifications
    ModelConcerns::Settings::Notification.new(notification_attributes).save_for(current_user)
    CombinedNotificationSetting.update_settings(parsed_combined_notifications_attrs, current_user) if params[:combined_notification_settings].present?
    flash[:success] = I18n.t('controllers.profiles.updated_notifications')
    redirect_to edit_notifications_profile_path
  end

  def notification_attributes
    params.require(:notifications).permit! if params[:notifications].present?
  end

  def parsed_combined_notifications_attrs
    if params[:combined_notification_settings].present?
      params.require(:combined_notification_settings).values.map do |setting|
        setting['frequency'] = setting['frequency'].gsub(/-\d+/, '').split(',').map { |v| v.strip.to_i }.reject(&:zero?)
        unless setting['frequency'].any?
          flash[:error] = "Couldn't parse your notification frequency. Value was reset to previous."
        end
        setting
      end
    end
  end
  ########  new functionality of notifications #########
  # def parsed_combined_notifications_attrs
  #   params.require(:combined_notification_settings).values
  # end
  ########  new functionality of notifications #########

  def password_attributes
    params.require(:profile).permit(:current_password, :password, :password_confirmation)
  end

  def profile_attributes
    if params[:profile].present?
      params.require(:profile).permit(
        :paypal_donations_url,
        :birthdate,
        :country,
        :email,
        :first_name,
        :slug,
        :last_name,
        :display_name,
        :gender,
        :public_display_name_source,
        :time_format,
        :talent_list,
        :manually_set_timezone,
        :currency,
        :current_password,
        :custom_slug_value,
        :password,
        :password_confirmation,
        :language,
        image_attributes: %i[crop_x crop_y crop_w crop_h rotate original_image],
        user_account_attributes: [:bio, :city, :country, :country_state, :found_us_method_id, :phone, :tagline,
                                  :available_by_request_for_live_vod, :talent_list, :contact_email,
                                  :crop_x, :crop_y, :crop_w, :crop_h, :rotate, :original_bg_image,
                                  { social_links_attributes: %i[link provider id] }]
      ).tap do |attributes|
        birthdate_keys = ['birthdate(1i)', 'birthdate(2i)', 'birthdate(3i)']
        if attributes.keys.any? { |k| k.include?('birthdate') } && birthdate_keys.all? do |key|
             attributes[key].present?
           end
          attributes['birthdate'] =
            Date.new(attributes['birthdate(1i)'].to_i, attributes['birthdate(2i)'].to_i,
                     attributes['birthdate(3i)'].to_i)
        end
        attributes.delete('custom_slug_value') if current_user.slug == attributes['custom_slug_value']
        if attributes.key?('custom_slug_value')
          attributes['custom_slug'] = true
        end
      end
    end
  end

  def prepare_soc_links
    social_links = current_user.user_account.social_links
    SocialLink::Providers::ORDERED_ALL.each do |provider|
      social_links.find { |sl| sl.provider.eql?(provider) } or
        social_links.build(entity: current_user.user_account, provider: provider)
    end
  end

  def avatar_attrs
    params.require(:profile).require(:image_attributes).permit(
      :crop_x, :crop_y, :crop_w, :crop_h, :rotate, :original_image
    )
  end
end
