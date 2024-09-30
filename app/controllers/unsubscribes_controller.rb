# frozen_string_literal: true

class UnsubscribesController < ApplicationController
  before_action :load_token

  def preview
    unless decoded_token
      flash[:error] = I18n.t('controllers.unsubscribes.invalid_token')
      redirect_to root_path
      return
    end

    #=> {subscriber_id:"#<User:0x007ff2c9b2a700>", email_name::new_follower_notification}

    @prefer_not_to_receive_description = email_setting_name
  end

  def confirm
    unless decoded_token
      flash[:error] = I18n.t('controllers.unsubscribes.invalid_token')
      redirect_to root_path
      return
    end

    user = User.find(decoded_token[:subscriber_id])

    notification_type = "#{decoded_token[:email_name]}_via_email"
    settings = RailsSettings::ScopedSettings.find_or_initialize_by(thing_id: user.id, thing_type: 'User', var: notification_type)
    settings.value = '0'
    settings.save!

    @settings_link = edit_notifications_profile_path if current_user.present?
    @email_type = email_setting_name
  end

  private

  def load_token
    @token = params[:token]
  end

  def decoded_token
    #=> {subscriber_id:"#<User:0x007ff2c9b2a700>", email_name::new_follower_notification}
    @decoded_token ||= Tldr::TokenGenerator.decode @token
  rescue ArgumentError => e
    nil
  end

  def email_setting_name
    I18n.t!("models.concerns.model_concerns.settings.notification.names.#{decoded_token[:email_name]}")
  rescue StandardError => e
    Airbrake.notify(e)
    decoded_token[:email_name]
  end
end
