# frozen_string_literal: true

module Im
  class ConversationsChannel < ApplicationCable::Channel
    EVENTS = {
      new_message: 'New message added to conversation. Data: { message: { id: message.id, body: message.body, created_at: message.created_at.utc.to_fs(:rfc3339), conversation_participant: { id: message.conversation_participant_id, abstract_user: { id: user.id, public_display_name: user.public_display_name, avatar_url: user.avatar_url, relative_path: user.relative_path } } }',
      message_updated: 'Conversation message updated. Data: { message: { id: message.id, body: message.body, created_at: message.created_at.utc.to_fs(:rfc3339) }, modified_at: message.modified.utc.to_fs(:rfc3339) } }',
      message_deleted: 'Conversation message marked as deleted. Data: { message: { id: message.id } }',
      channel_conversation_disabled: 'Channel conversation disabled. Data: {}'
    }.freeze

    def subscribed
      stream_from 'im/conversations_channel'
      return unless (conversation = ::Im::Conversation.find_by(id: params[:data]))

      stream_for conversation if current_ability.can?(:read_im_conversation, conversation.conversationable)
    end

    def unsubscribed
      # Any cleanup needed when channel is unsubscribed
    end

    private

    def current_ability
      @current_ability ||= AbilityLib::ChannelAbility.new(current_user).merge(AbilityLib::SessionAbility.new(current_user || current_guest))
    end
  end
end
