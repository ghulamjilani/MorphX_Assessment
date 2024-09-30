# frozen_string_literal: true

envelope json, (@status || 200) do
  json.conversations do
    json.array! @conversations do |conversation|
      json.conversation do
        json.partial! 'api/v1/user/im/conversations/conversation', conversation: conversation

        if (message = conversation.last_message)
          json.last_message do
            json.partial! 'api/v1/user/im/messages/message', message: message

            json.conversation_participant do
              json.id message.conversation_participant.id
              json.banned message.conversation_participant.banned

              json.abstract_user do
                json.partial! 'api/v1/user/im/messages/abstract_user', abstract_user: message.conversation_participant.abstract_user
              end
            end
          end
        else
          json.last_message nil
        end

        json.can_create_message can?(:create_im_message, conversation.conversationable)
        json.can_moderate_conversation can?(:moderate_im_conversation, conversation.conversationable)
      end

      case conversation.conversationable
      when Channel
        json.channel do
          json.partial! 'api/v1/user/channels/channel_short', channel: conversation.conversationable
        end
      when Session
        session = conversation.conversationable
        json.session do
          json.partial! 'session', session: session

          json.channel do
            json.partial! 'api/v1/user/channels/channel_short', channel: session.channel
          end
        end
      else
        json.channel nil
        json.session nil
      end
    end
  end
end
