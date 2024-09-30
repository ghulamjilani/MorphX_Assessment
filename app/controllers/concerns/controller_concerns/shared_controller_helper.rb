# frozen_string_literal: true

module ControllerConcerns::SharedControllerHelper
  extend ActiveSupport::Concern

  included do
    helper_method :current_ability
    helper_method :used_time_format
    helper_method :used_timezone
    helper_method :video_anchor
    helper_method :organization_default_user_path

    before_action :gon_init, unless: -> { activeadmin_request? }
    skip_before_action :gon_init, if: -> { request.path.starts_with? '/kss/' }

    before_action :extract_refc_from_url_into_cookie, unless: -> { activeadmin_request? }
    before_action :check_if_referral_user, if: :user_signed_in?, unless: -> { activeadmin_request? }

    before_action :persist_timezone_if_not_yet_specified, unless: -> { activeadmin_request? }
    before_action :set_timezone, unless: -> { activeadmin_request? }
    before_action :set_admin_timezone, if: -> { activeadmin_request? }

    after_action :prepare_unobtrusive_flash, unless: -> { activeadmin_request? }

    unless Rails.env.test?
      rescue_from CanCan::AccessDenied do |exception|
        @exception_message = exception.message

        respond_to do |format|
          format.html { render 'errors/access_denied', status: 403, layout: 'error' }
          format.json { render json: @exception_message, status: 403 }
        end
      end
    end
  end

  def activeadmin_request?
    request.path.starts_with?("/#{ActiveAdmin.application.default_namespace}")
  end

  def video_anchor(session, id = nil)
    id ||= session.primary_record.try(:id)
    id ? "?video_id=#{id}" : ''
  end

  def recording_anchor(id = nil)
    # id ||= session.channel.recordings.first.try(:id)
    id ? "?recording_id=#{id}" : ''
  end

  # Notice it is important to cache the ability object so it is not
  # recreated every time.
  def current_ability
    @current_ability ||= ::AbilityLib::ChannelAbility.new(current_user).tap do |ability|
      ability.merge(::AbilityLib::AccessManagement::GroupAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::ImageAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::PostAbility.new(current_user))
      ability.merge(::AbilityLib::StripeDb::ServiceSubscriptionAbility.new(current_user))
      ability.merge(::AbilityLib::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationMembershipAbility.new(current_user))
      ability.merge(::AbilityLib::PendingRefundAbility.new(current_user))
      ability.merge(::AbilityLib::RecordingAbility.new(current_user))
      ability.merge(::AbilityLib::ReviewAbility.new(current_user))
      ability.merge(::AbilityLib::SessionAbility.new(current_user))
      ability.merge(::AbilityLib::SessionInvitedImmersiveParticipantshipAbility.new(current_user))
      ability.merge(::AbilityLib::SessionInvitedLivestreamParticipantshipAbility.new(current_user))
      ability.merge(::AbilityLib::SubscriptionAbility.new(current_user))
      ability.merge(::AbilityLib::UserAbility.new(current_user))
      ability.merge(::AbilityLib::VideoAbility.new(current_user))
    end
  end

  def logger_user_tag
    "[#{request.env['HTTP_USER_AGENT']}]".tap do |result|
      result += "[#{current_user.try(:id)}]" if user_signed_in?
    end
  end

  def used_time_format
    if user_signed_in?
      current_user.time_format
    else
      User::TimeFormats::HOUR_12
    end
  end

  def used_timezone
    if user_signed_in?
      current_user.timezone or raise("can't find default timezone")
    else
      User.new.timezone or raise("can't find default timezone")
    end
  end

  private

  def gon_init
    gon.time_format            = used_time_format
    gon.environment            = Rails.env
    # gon.popup_close_image_url  = view_context.image_path('landingPage/signup_images/popup_close.png')

    if user_signed_in?
      gon.can_create_free_private_sessions_without_permission = current_user.can_create_free_private_sessions_without_permission

      gon.video_credentials = {
        id: current_user.id,
        auth_token: current_user.authentication_token
      } # REMOVEME

      gon.current_user_id = current_user.id
      gon.current_user = {
        id: current_user.id,
        env: Rails.env,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        display_name: current_user.display_name,
        email: current_user.email,
        gender: current_user.gender,
        user_admin_url: service_admin_panel_user_url(current_user.id),
        created_at: current_user.created_at
      }
      if current_user.birthdate.present?
        user_lifetime = Time.zone.now - current_user.birthdate.to_time
        gon.current_user[:age] = ActiveSupport::Duration.build(user_lifetime).parts[:years]
      else
        gon.current_user[:age] = nil
      end

      gon.timezone_offset = ActiveSupport::TimeZone.new(current_user.timezone).now.strftime('%z')
      gon.timezone        = ActiveSupport::TimeZone.find_tzinfo(current_user.timezone).friendly_identifier
    end
  end

  def extract_refc_from_url_into_cookie
    if !user_signed_in? && params[:refc].present?
      cookies.permanent.signed[:refc] = params[:refc]
      Rails.logger.info logger_user_tag + "set refc cookie to #{cookies.signed[:refc]}"
    end
  end

  def check_if_referral_user
    code = cookies.signed[:refc]
    if code.present? && !current_user.someones_referral_user?
      Rails.logger.info logger_user_tag + "refc cookie is present: #{code}"

      referral_code = ReferralCode.find_by(code: code)
      if referral_code.present?
        Referral.create!(user: current_user, referral_code_id: referral_code.id, master_user_id: referral_code.user.id)
        Rails.logger.info logger_user_tag + "set as referral of ##{referral_code.user.id} #{referral_code.user.email}"
      else
        notify_airbrake(RuntimeError.new('suspicious signup attempt with invalid referral code'),
                        parameters: {
                          current_user_id: current_user.id,
                          code: code
                        })
      end

      cookies.delete(:refc)
    end
  end

  # this fixes #1464 - for those users who never set their timezone manually and only have a default timezone
  # despite already given permission in browser
  def persist_timezone_if_not_yet_specified
    if user_signed_in? && current_user.manually_set_timezone.blank? && cookies[:tzinfo].present? && cookies[:tzinfo] != 'false'
      # cookies[:tzinfo]
      #=> "Europe/Kiev"
      current_user.update_attribute(:manually_set_timezone, User.available_timezones.detect do |tz|
                                                              tz.formatted_offset == cookies[:tzinfo]
                                                            end.try(:tzinfo).try(:name))
    end
  end

  def set_timezone
    Time.zone = used_timezone
  end

  def set_admin_timezone
    return if current_admin&.manually_set_timezone.blank?

    Time.zone = current_admin.manually_set_timezone
  end

  def organization_default_user_path(organization)
    if (default_channel = organization.default_user_channel(current_user))
      return default_channel.relative_path
    end

    relative_path
  end
end
