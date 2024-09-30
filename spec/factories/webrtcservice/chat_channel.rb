# frozen_string_literal: true

FactoryBot.define do
  factory :webrtcservice_chat_channel, class: 'ChatChannel' do
    webrtcservice_id { SecureRandom.alphanumeric(8).downcase }
  end

  factory :aa_stub_webrtcservice_chatchannel, parent: :webrtcservice_chat_channel
end
