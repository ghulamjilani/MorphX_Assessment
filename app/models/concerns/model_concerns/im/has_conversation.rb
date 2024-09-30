# frozen_string_literal: true

module ModelConcerns
  module Im
    module HasConversation
      extend ActiveSupport::Concern

      included do
        has_one :im_conversation, class_name: '::Im::Conversation', as: :conversationable, dependent: :nullify
        has_many :im_conversation_participants, class_name: '::Im::ConversationParticipant', through: :im_conversation, source: :conversation_participants
        has_many :im_messages, class_name: '::Im::Message', through: :im_conversation, source: :messages

        def assign_im_conversation
          self.im_conversation ||= ::Im::Conversation.create_or_find_by(conversationable: self)
        end

        def im_conversation_closed?
          false
        end
      end
    end
  end
end
