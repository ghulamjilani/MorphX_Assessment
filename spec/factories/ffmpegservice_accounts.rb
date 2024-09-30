# frozen_string_literal: true
FactoryBot.define do
  factory :ffmpegservice_account do
    stream_id { SecureRandom.alphanumeric(8).downcase }
    stream_name { 'testss' }
    custom_name { "#{Forgery('name').company_name} #{rand(0...9999)}" }
    port { '123123' }
    organization_id { nil }
    user_id { nil }
    reserved_by_id { nil }
    reserved_by_type { nil }
    current_service { 'main' }
    delivery_method { 'push' }
    transcoder_type { 'passthrough' }
    sandbox { true }
    hls_url { 'https://cds.c5r2q9u4.hwcdn.net/3/4540/rid4540_uid3_d237f666e19710e5dd58dea66bb14d31.mp4' }
    sdp_url { 'wss://abcdef.entrypoint.cloud.ffmpegservice.com/webrtc-session.json' }
    application_name { 'abcdef' }
    protocol { 'rtmp' }
    playback_stream_name { 'fedcba' }
  end

  factory :ffmpegservice_account_webrtc, parent: :ffmpegservice_account do
    protocol { 'webrtc' }
    transcoder_type { 'transcoded' }
  end

  factory :ffmpegservice_account_rtmp, parent: :ffmpegservice_account do
    current_service { 'rtmp' }
    server { 'rtmp://abcdef.entrypoint.cloud.ffmpegservice.com/app-abc345def' }
    username { 'abcdefgh' }
    password { 'hgfedcba' }
  end

  factory :ffmpegservice_account_ipcam, parent: :ffmpegservice_account do
    current_service { 'ipcam' }
    delivery_method { 'pull' }
    protocol { 'rtsp' }
  end

  factory :ffmpegservice_account_reserved, parent: :ffmpegservice_account do
    reserved_by { create(:organization) }
  end

  factory :ffmpegservice_account_free_pull, parent: :ffmpegservice_account do
    current_service { 'ipcam' }
    delivery_method { 'pull' }
    protocol { 'rtsp' }
  end

  factory :ffmpegservice_account_free_pull_reserved, parent: :ffmpegservice_account_free_pull do
    reserved_by { create(:organization) }
  end

  factory :ffmpegservice_account_free_push, parent: :ffmpegservice_account do
    delivery_method { 'push' }
    transcoder_type { 'passthrough' }
  end

  factory :ffmpegservice_account_free_push_reserved, parent: :ffmpegservice_account_free_push do
    reserved_by { create(:organization) }
  end

  factory :ffmpegservice_account_paid_push, parent: :ffmpegservice_account do
    delivery_method { 'push' }
    transcoder_type { 'transcoded' }
  end

  factory :ffmpegservice_account_paid_push_reserved, parent: :ffmpegservice_account_paid_push do
    reserved_by { create(:organization) }
  end

  factory :ffmpegservice_account_paid_pull, parent: :ffmpegservice_account_ipcam do
    transcoder_type { 'transcoded' }
  end

  factory :ffmpegservice_account_paid_pull_reserved, parent: :ffmpegservice_account_paid_pull do
    reserved_by { create(:organization) }
  end

  factory :ffmpegservice_account_assigned, parent: :ffmpegservice_account do
    organization { create(:organization) }
  end

  factory :aa_stub_ffmpegservice_accounts, parent: :ffmpegservice_account
  factory :aa_stub_ffmpegservice_status, parent: :ffmpegservice_account
end
