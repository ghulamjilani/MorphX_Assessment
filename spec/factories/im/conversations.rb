# frozen_string_literal: true
FactoryBot.define do
  factory :im_conversation, class: 'Im::Conversation' do
    conversationable { nil }
    organization_id { nil }
  end

  factory :im_channel_conversation, parent: :im_conversation do
    conversationable { create(:listed_channel, im_conversation_enabled: false) }
    organization_id { conversationable.organization_id }
    after(:create) do |conversation|
      conversation.conversationable.update_column(:im_conversation_enabled, true)
    end
  end

  factory :im_session_conversation, parent: :im_conversation do
    conversationable { create(:published_livestream_session, allow_chat: false) }
    organization_id { conversationable.organization_id }
    after(:create) do |conversation|
      conversation.conversationable.update_column(:allow_chat, true)
    end
  end

  factory :aa_stub_im_conversations, parent: :im_conversation
end
