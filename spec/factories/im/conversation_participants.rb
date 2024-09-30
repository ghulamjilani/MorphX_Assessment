# frozen_string_literal: true
FactoryBot.define do
  factory :im_conversation_participant, class: 'Im::ConversationParticipant' do
    conversation { create(:im_conversation) }
    abstract_user { create(:user) }
  end

  factory :im_conversation_guest_participant, parent: :im_conversation_participant do
    conversation { create(:im_session_conversation) }
    abstract_user { create(:guest) }
  end

  factory :aa_stub_im_conversation_participants, parent: :im_conversation_participant
end
