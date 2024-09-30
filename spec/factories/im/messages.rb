# frozen_string_literal: true
FactoryBot.define do
  factory :im_message, class: 'Im::Message' do
    conversation_participant { create(:im_conversation_participant) }
    conversation { conversation_participant.conversation }
    body { Forgery(:lorem_ipsum).words(10, random: true) }
  end

  factory :im_guest_message, parent: :im_message do
    conversation_participant { create(:im_conversation_guest_participant) }
  end

  factory :aa_stub_im_messages, parent: :im_message
end
