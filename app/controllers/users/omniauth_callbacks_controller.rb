# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include ControllerConcerns::MobileSocialsValidator
  include ControllerConcerns::Api::V1::CookieAuth
  include ControllerConcerns::Api::V1::HasJwtAuth

  ModelConcerns::User::ActsAsOmniauthUser::PROVIDERS.keys.each do |provider|
    define_method(provider) do
      social_authenticate(provider.to_sym)
    end
  end

  def failure
    respond_to do |format|
      format.html do
        set_flash_message :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name),
                                            reason: failure_message
        origin = begin
          cookies.delete(:social_auth_origin)
        rescue StandardError
          nil
        end
        if !origin || origin != 'signup'
          redirect_to after_omniauth_failure_path_for(resource_name) and return
        end

        redirect_to after_omniauth_signup_failure_path
      end
      format.json { render_json(401, "#{OmniAuth::Utils.camelize(failed_strategy.name)} : #{failure_message}") }
    end
  end

  def verify
    @payload = case params[:provider]
               when 'gplus'
                 verify_google(params)
               when 'apple'
                 verify_apple(params)
               when 'facebook'
                 verify_facebook(params)
               when 'linkedin'
                 verify_linkedin(params)
               when 'twitter'
                 verify_twitter(params)
               when 'instagram'
                 verify_instagram(params)
               else
                 empty_playload
               end

    if @payload.verify
      social_authenticate(params[:provider].to_sym)
    else
      render_json(401, @payload.message)
    end
  rescue StandardError => e
    notify_airbrake(e)
    render_json 500, e.message, e
  end

  def setup
    if params[:provider] == 'gplus' && params.has_key?(:youtube)
      request.env['omniauth.strategy'].options[:scope] = 'email, profile, https://gdata.youtube.com'
    end
    head :ok
  end

  protected

  def after_omniauth_signup_failure_path
    new_user_registration_path
  end

  private

  def after_sign_in_path_for(resource_or_scope)
    @after_sign_in_path ||= if request.referer == root_url
                              dashboard_path
                            else
                              session['return_to_url'] || params['redirect_to'] ||
                                session.delete(RETURN_TO_AFTER_CONNECTING_ACCOUNT) ||
                                request.env['omniauth.origin'] ||
                                stored_location_for(resource_or_scope) || signed_in_root_path(resource_or_scope)
                            end
  end

  def omniauth_params
    # could be for example:
    #=> {"devise_invitation_token" => "zxc"}
    request.env['omniauth.params']
  end

  def devise_invitation_token
    omniauth_params['devise_invitation_token']
  rescue StandardError
    nil
  end

  def devise_redirect_path_after_social_signup
    omniauth_params['redirect_path_after_social_signup'] || cookies.delete(:redirect_back_to_after_signup)
  rescue StandardError
    nil
  end

  def payload
    @payload || request.env['omniauth.auth']
  end

  def omniauth_token
    return payload.credentials.token if payload.credentials.present? && payload.credentials.token
  end

  def omniauth_expires
    return payload.credentials.expires if payload.credentials.present? && payload.credentials.expires
  end

  def omniauth_expires_at
    return Time.at(payload.credentials.expires_at) if payload.credentials.present? && payload.credentials.expires_at
  end

  def omniauth_secret
    return payload.credentials.secret if payload.credentials.present? && payload.credentials.secret
    return payload.credentials.refresh_token if payload.credentials.present? && payload.credentials.refresh_token.present?
  end

  def fill_addition_info(user)
    if payload.provider.to_s == 'facebook'
      # Set image from fb if user does not have an avatar
      if user.image.blank?
        res = Net::HTTP.get_response(URI("http://graph.facebook.com/#{payload.uid}/picture?type=large"))
        i = user.build_image
        i.remote_original_image_url = res['location']
        i.save(validate: false)
      end
      user.save_facebook_friends(payload)
    elsif payload.info.image.present? && user.image.blank?
      i = user.build_image
      i.remote_original_image_url = payload.info.image
      i.save(validate: false)
    end
  end

  def social_authenticate(type)
    Rails.logger.info payload

    raise unless ModelConcerns::User::ActsAsOmniauthUser::PROVIDERS.key?(type)

    # INVALID INVITATION TOKEN
    if devise_invitation_token.present? && !User.exists?(invitation_token: devise_invitation_token)
      session["devise.#{type}_data"] = payload.to_h.except('extra')
      flash[:warning] = I18n.t('devise.invitations.invitation_token_invalid')
      redirect_path = devise_redirect_path_after_social_signup || new_user_registration_url
      respond_to do |format|
        format.html { redirect_to redirect_path }
        format.json { render 'social_authenticate.json', locals: { redirect_path: redirect_path, user: nil } }
      end and return
    end

    # check if SN already associated with existing user
    identity = Identity.find_by(provider: payload.try(:provider), uid: payload.try(:uid))

    if identity.present?
      # SN Identity present
      if devise_invitation_token.present?
        user = User.find_by(invitation_token: devise_invitation_token)
        if identity.user == user # Account linked to invited user
          if user.first_name.blank?
            payload['tzinfo'] = cookies[:tzinfo]
            user.attributes = User.send(:"#{type}_attributes_to_assign_from_payload", payload)
            user.before_create_generic_callbacks_and_skip_validation
            user.save!
          end
          # user.confirm! NOTE: do not uncomment - if fails and hides stacktrace. But it's ok - we can not confirm email right away, they may be different!
          user.confirmation_token = nil
          user.confirmed_at ||= Time.zone.now
          user.accept_invitation!
          sign_in(:user, user)
          auth_user_token = ::Auth::UserToken.create!(user: user, device: request.user_agent, ip: request.remote_ip)
          create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: auth_user_token)
          fill_addition_info(current_user)
          redirect_path = devise_redirect_path_after_social_signup || after_sign_in_path_for(current_user)
        else
          # Account linked to another user
          flash[:warning] =
            I18n.t 'devise.omniauth_callbacks.failure', kind: ModelConcerns::User::ActsAsOmniauthUser::PROVIDERS[type.to_sym],
                                                        reason: 'account is already linked to other user.'
          redirect_path = request.env['omniauth.origin'] || new_user_registration_url
        end
        respond_to do |format|
          format.html { redirect_to redirect_path }
          format.json { render 'social_authenticate.json', locals: { redirect_path: redirect_path, user: user } }
        end and return
      elsif user_signed_in? # User trying to connect SN from settings page
        if identity.user != current_user # Account linked to another user
          flash[:warning] =
            I18n.t 'devise.omniauth_callbacks.failure', kind: ModelConcerns::User::ActsAsOmniauthUser::PROVIDERS[type.to_sym],
                                                        reason: 'account is already linked to other user.'
        else
          fill_addition_info(current_user)
          save_social_link(current_user)
          flash[:warning] = 'You have already linked this account'
        end
        redirect_path = request.env['omniauth.origin']&.include?('wizard') ? request.env['omniauth.origin'] : edit_application_profile_path
        auth_user_token = ::Auth::UserToken.create!(user: current_user, device: request.user_agent, ip: request.remote_ip)
        create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: auth_user_token)
        sign_in(:user, current_user)
      else
        # User exists so just sign in him
        sign_in(:user, identity.user)
        fill_addition_info(current_user)
        save_social_link(current_user)
        auth_user_token = ::Auth::UserToken.create!(user: current_user, device: request.user_agent, ip: request.remote_ip)
        create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: auth_user_token)
      end
      # update identity if this is google
      if payload.provider.to_s == 'gplus'
        identity.token = omniauth_token
        identity.expires = omniauth_expires
        identity.expires_at = omniauth_expires_at
        identity.secret = omniauth_secret
        identity.save
      end
      redirect_path ||= devise_redirect_path_after_social_signup || after_sign_in_path_for(current_user)
      respond_to do |format|
        format.html { redirect_to redirect_path }
        format.json { render 'social_authenticate.json', locals: { redirect_path: redirect_path, user: current_user } }
      end and return
    else
      # New SN in system
      if devise_invitation_token.present? && (user = User.find_by(invitation_token: devise_invitation_token))
        # invited user without filled profile
        if user.first_name.blank?
          payload['tzinfo'] = cookies[:tzinfo]
          user.attributes = User.send(:"#{type}_attributes_to_assign_from_payload", payload)
          user.before_create_generic_callbacks_and_skip_validation
          user.save!
        end
        vs_attrs = {
          user_id: user.id,
          refc: cookies.permanent.signed[:refc],
          current: cookies[:sbjs_current],
          current_add: cookies[:sbjs_current_add],
          first: cookies[:sbjs_first],
          first_add: cookies[:sbjs_first_add],
          session: cookies[:sbjs_session],
          udata: cookies[:sbjs_udata],
          tzinfo: cookies[:tzinfo]
        }
        VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)
        Mailer.user_signed_up(user.id).deliver_later

        # user.confirm! NOTE: do not uncomment - if fails and hides stacktrace. But it's ok - we can not confirm email right away, they may be different!
        user.confirmation_token = nil
        user.confirmed_at ||= Time.zone.now
        user.accept_invitation!
        save_social_link(user)
        sign_in user
        redirect_path = after_accept_path_for(current_user)
      end

      if user_signed_in?
        auth_user_token = ::Auth::UserToken.create!(user: current_user, device: request.user_agent, ip: request.remote_ip)
        create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: auth_user_token)
        sign_in(:user, current_user)
        if current_user.identities.exists?(provider: payload.provider.to_s)
          flash[:warning] = 'You have already linked another account'
          redirect_path ||= root_path
        else
          current_user.identities.create!(identity_attributes)

          if payload.info.email.present? && current_user.email == payload.info.email
            # because confirmation_sent_at could be nil and then it would fail otherwise
            def current_user.confirmation_period_expired?
              false
            end

            # fixes #1223, #1435
            current_user.confirm
            current_user.accept_invitation!
          end
          flash[:notice] = 'Account successfully linked'
          redirect_path ||= devise_redirect_path_after_social_signup || after_sign_in_path_for(current_user)
        end
        fill_addition_info(current_user)
        save_social_link(current_user)
        respond_to do |format|
          format.html { redirect_to redirect_path }
          format.json do
            render 'social_authenticate.json', locals: { redirect_path: redirect_path, user: current_user }
          end
        end and return
      elsif payload
        # Try to find existing user by email from payload
        if payload.info.email.present? && (user = User.find_by(email: payload.info.email.to_s.downcase))
          if user.identities.where(provider: payload.provider).present?
            flash[:warning] = I18n.t('signup.email_used_try_reset_password', email: payload.info.email.to_s.downcase)
            user = User.new
          else
            user.identities.create!(identity_attributes)
            save_social_link(user)
            # because confirmation_sent_at could be nil and then it would fail otherwise
            def user.confirmation_period_expired?
              false
            end

            # fixes #1223, #1435
            user.confirm
            user.accept_invitation!
          end
        else
          # Create new user and link account
          payload['tzinfo'] = cookies[:tzinfo]
          user = User.send(:"create_from_#{type}", payload)
          if user.persisted?
            vs_attrs = {
              user_id: user.id,
              refc: cookies.permanent.signed[:refc],
              current: cookies[:sbjs_current],
              current_add: cookies[:sbjs_current_add],
              first: cookies[:sbjs_first],
              first_add: cookies[:sbjs_first_add],
              session: cookies[:sbjs_session],
              udata: cookies[:sbjs_udata],
              tzinfo: cookies[:tzinfo]
            }
            VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)
            Mailer.user_signed_up(user.id).deliver_later
          end
        end

        if user.persisted?
          fill_addition_info(user)
          flash[:success] =
            I18n.t 'devise.omniauth_callbacks.success', kind: ModelConcerns::User::ActsAsOmniauthUser::PROVIDERS[type.to_sym]
          user.remember_me = true
          user.accept_invitation!

          # follow_redirect = devise_redirect_path_after_social_signup.present?
          #
          # if follow_redirect && devise_redirect_path_after_social_signup == become_presenter_steps_path &&
          #     user.presenter.present? && user.presenter.channels.present?
          #   follow_redirect = false
          # end

          redirect_path = devise_redirect_path_after_social_signup || after_sign_in_path_for(user)
          sign_in(:user, user)
          auth_user_token = ::Auth::UserToken.create!(user: current_user, device: request.user_agent, ip: request.remote_ip)
          create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: auth_user_token)
          respond_to do |format|
            format.html { redirect_to redirect_path }
            format.json { render 'social_authenticate.json', locals: { redirect_path: redirect_path, user: user } }
          end
        else
          session["devise.#{type}_data"] = payload.to_h.except('extra')
          respond_to do |format|
            format.html { redirect_to new_user_registration_url }
            format.json do
              render 'social_authenticate.json', locals: { redirect_path: new_user_registration_url, user: nil }
            end
          end
        end
      end
    end
  end

  def identity_attributes
    return {} unless payload

    {
      provider: payload.provider,
      uid: payload.uid,
      token: omniauth_token,
      expires: omniauth_expires,
      expires_at: omniauth_expires_at,
      secret: omniauth_secret
    }
  end

  def save_social_link(user)
    unless user.user_account
      user.build_user_account
      user.save(validate: false)
    end
    case payload.provider
    when 'facebook'
      return unless payload.info.urls

      if payload.info.urls['Facebook'] && !user.user_account.social_links.exists?(provider: 'facebook')
        user.user_account.social_links.create(provider: 'facebook', link: payload.info.urls['Facebook'])
      end
    when 'gplus'
      return unless payload.info.urls

      if payload.info.urls['Google'] && !user.user_account.social_links.exists?(provider: 'google+')
        user.user_account.social_links.create(provider: 'google+', link: payload.info.urls['Google'])
      end
    when 'twitter'
      return unless payload.info.urls

      if payload.info.urls['Twitter'] && !user.user_account.social_links.exists?(provider: 'twitter')
        user.user_account.social_links.create(provider: 'twitter', link: payload.info.urls['Twitter'])
      end
      if payload.info.urls['Website'] && !user.user_account.social_links.exists?(provider: 'explicit')
        user.user_account.social_links.create(provider: 'explicit', link: payload.info.urls['Website'])
      end
    when 'linkedin'
      return unless payload.info.urls

      if payload.info.urls['public_profile'] && !user.user_account.social_links.exists?(provider: 'linkedin')
        user.user_account.social_links.create(provider: 'linkedin', link: payload.info.urls['public_profile'])
      end
    when 'instagram'
      unless user.user_account.social_links.exists?(provider: 'instagram')
        user.user_account.social_links.create(provider: 'instagram', link: payload.info.nickname)
      end
      if payload.info.website.length && !user.user_account.social_links.exists?(provider: 'explicit')
        user.user_account.social_links.create(provider: 'explicit', link: payload.info.website)
      end
    end
  end
end
