# frozen_string_literal: true

envelope json, (@status || 200), (@conversation.pretty_errors if @conversation.errors.present?) do
  json.conversation do
    json.partial! 'conversation', conversation: @conversation

    json.conversationable do
      json.partial! 'conversationable', conversationable: @conversationable
    end

    if (message = @conversation.last_message)
      json.last_message do
        json.partial! 'api/v1/user/im/messages/message', message: message

        if message.conversation_participant&.abstract_user
          json.conversation_participant do
            json.partial! 'api/v1/user/im/conversation_participants/conversation_participant', conversation_participant: message.conversation_participant

            json.abstract_user do
              json.partial! 'api/v1/user/im/messages/abstract_user', abstract_user: message.conversation_participant.abstract_user
            end
          end
        end
      end
    else
      json.last_message nil
    end

    json.can_create_message can?(:create_im_message, @conversationable)
    json.can_moderate_conversation can?(:moderate_im_conversation, @conversationable)
  end
end
