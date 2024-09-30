# frozen_string_literal: true

Warden::Manager.after_authentication do |user, auth, _opts|
  UpdateUserAgent.perform_async user.id, auth.request.user_agent, auth.request.remote_ip
  PullCountryInfoForIpAddress.perform_async auth.request.remote_ip
end
