# frozen_string_literal: true

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |name, start, _finish, request_id, payload|
  if payload[:request].env['rack.attack.matched'] == 'req/ip'
    Rails.logger.warn("[#{request_id}][#{name}][#{start}][#{payload[:request].ip}] #{payload[:request].path} 429 Complete")
  end
end

Rack::Attack.throttle('contact_us/lets_talk/ip', limit: 3, period: 1.minute) do |req|
  if req.path == '/lets_talk'
    "rack:attack:contact_us:lets_talk:#{req.ip}"
  else
    false
  end
end
# prevents one session from being shared by one user(IP) more that 8 times during 12 hours period
Rack::Attack.throttle('shares/increment/id/ip', limit: 8, period: 12.hours) do |req|
  if req.path == '/shares/increment'
    "rack:attack:share_increment:#{req.params['id']}:#{req.ip}"
  else
    false
  end
end

Rack::Attack.throttle('req/ip', limit: 5, period: 1.second) do |req|
  unless req.path.starts_with?('/assets') || req.path.include?('image') || req.path.include?('thumbnail') ||
         req.path.starts_with?('/widgets') || req.path.starts_with?('/webrtcservice') || req.path.starts_with?('/stripe') ||
         req.path.starts_with?('/server_time') || req.path.include?('/reviews') ||
         req.path.starts_with?('/api/v1') || # skip for our api
         req.path.include?('/dashboard') ||
         req.path.include?('/replays_list') ||
         req.path.include?('/rails') ||
         req.path.include?('/docs') ||
         req.path.include?('/sessions_list') || req.path.include?('/recordings_list')
    req.ip
  end
end

Rack::Attack.throttle('api/req/ip', limit: 20, period: 1.second) do |req|
  req.ip if req.path.starts_with?('/api/v1')
end

Rails.application.credentials.backend.dig(:rack_attack, :whitelist_ip).to_a.each do |ip|
  Rack::Attack.safelist_ip(ip)
end
