# frozen_string_literal: true
FactoryBot.define do
  factory :transcoder_uptime do
    streamable { create(:recorded_session).room }
    transcoder_id { puts streamable.inspect; streamable.session.ffmpegservice_account.stream_id }
    uptime_id { SecureRandom.alphanumeric(8).downcase }
  end

  factory :aa_stub_transcoder_uptimes, parent: :transcoder_uptime
end
