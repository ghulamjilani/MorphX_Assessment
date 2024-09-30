# frozen_string_literal: true
module Im
  class Conversation < Im::ApplicationRecord
    has_many :conversation_participants, class_name: '::Im::ConversationParticipant', inverse_of: :conversation, dependent: :destroy
    # has_many :users, through: :conversation_participants, source: :user
    belongs_to :conversationable, polymorphic: true
    before_validation :set_organization_id, if: :conversationable_changed?

    has_one :last_message, -> { not_deleted.order(created_at: :desc) }, class_name: '::Im::Message', inverse_of: :conversation

    has_many :messages, class_name: '::Im::Message', inverse_of: :conversation, dependent: :destroy

    scope :for_channel, -> { where(conversationable_type: 'Channel') }
    scope :for_session, -> { where(conversationable_type: 'Session') }

    def closed?
      return false unless conversationable

      conversationable.im_conversation_closed?
    end

    private

    def set_organization_id
      self.organization_id = conversationable&.organization_id
    end
  end
end
