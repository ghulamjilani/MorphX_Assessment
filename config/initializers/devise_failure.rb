# frozen_string_literal: true

class DeviseFailure < Devise::FailureApp
  def redirect_url
    if warden_message == :timeout
      # flash[:timedout] = true

      path = if request.get?
               attempted_path
             else
               request.referrer
             end
      path || scope_url
    elsif warden_options[:scope] == :user
      session['autodisplay_modal'] = LandingHelper::SIGN_IN_MODAL
      request.referer || root_path
    elsif warden_options[:scope] == :admin
      new_admin_session_path
    else
      new_user_registration_path
    end
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
