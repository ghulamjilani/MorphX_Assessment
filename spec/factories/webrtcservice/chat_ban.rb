# frozen_string_literal: true

FactoryBot.define do
  factory :webrtcservice_chat_ban, class: 'ChatBan' do
    ip_address { Forgery(:internet).ip_v4 }
  end

  factory :aa_stub_webrtcservice_chatban, parent: :webrtcservice_chat_ban
end
