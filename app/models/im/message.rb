# frozen_string_literal: true
module Im
  class Message < Im::ApplicationRecord
    include ModelConcerns::ActiveModel::Extensions

    belongs_to :conversation, class_name: '::Im::Conversation', optional: false, touch: true
    belongs_to :conversation_participant, class_name: '::Im::ConversationParticipant', optional: false

    validates :body, presence: true, length: { in: 1..200 }

    before_validation :sanitize_body
    after_create :notify_conversation_new_message
    after_update :notify_conversation_message_updated, if: proc { |message| message.saved_change_to_body? }
    after_update :notify_conversation_message_deleted, if: proc { |message| message.saved_change_to_deleted_at? && message.deleted? }
    after_destroy :notify_conversation_message_deleted

    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }

    def deleted?
      deleted_at.present?
    end

    def deleted!
      update(deleted_at: Time.now.utc)
    end

    def restore!
      update(deleted_at: nil)
    end

    delegate :conversationable, to: :conversation
    delegate :abstract_user, to: :conversation_participant

    private

    def notify_conversation_new_message
      data = {
        message: {
          id: id,
          conversation_id: conversation_id,
          conversation_participant_id: conversation_participant_id,
          body: body,
          created_at: created_at.utc.to_fs(:rfc3339),
          conversation_participant: {
            id: conversation_participant_id,
            abstract_user: {
              id: abstract_user.id,
              public_display_name: abstract_user.public_display_name,
              avatar_url: abstract_user.avatar_url,
              relative_path: abstract_user.relative_path
            }
          }
        }
      }
      ::Im::ConversationsChannel.broadcast_to conversation, event: 'new_message', data: data
    end

    def notify_conversation_message_updated
      data = {
        message: {
          id: id,
          body: body,
          created_at: created_at.utc.to_fs(:rfc3339),
          modified_at: modified_at&.utc&.to_fs(:rfc3339)
        }
      }
      ::Im::ConversationsChannel.broadcast_to conversation, event: 'message_updated', data: data
    end

    def notify_conversation_message_deleted
      data = { message: { id: id } }
      ::Im::ConversationsChannel.broadcast_to conversation, event: 'message_deleted', data: data
    end

    def sanitize_body
      self.body = Html::Parser.new(Nokogiri::HTML.parse(body).inner_text).remove_scripts.to_s.strip
    end
  end
end
