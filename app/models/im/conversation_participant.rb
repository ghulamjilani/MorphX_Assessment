# frozen_string_literal: true
module Im
  class ConversationParticipant < Im::ApplicationRecord
    belongs_to :abstract_user, polymorphic: true, optional: false
    belongs_to :conversation, class_name: '::Im::Conversation', touch: true

    has_many :messages, class_name: '::Im::Message', inverse_of: :conversation_participant, dependent: :destroy

    scope :banned, -> { where(banned: true) }
  end
end
