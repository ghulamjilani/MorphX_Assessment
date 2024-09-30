# frozen_string_literal: true

FactoryBot.define do
  factory :webrtcservice_chat_member, class: 'ChatMember' do
    name { Forgery('name').first_name }
  end

  factory :aa_stub_webrtcservice_chatmember, parent: :webrtcservice_chat_member
end
