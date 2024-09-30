# frozen_string_literal: true

envelope json, (@status || 200) do
  json.messages do
    json.array! @messages do |message|
      json.message do
        json.partial! 'message', message: message

        json.conversation_participant do
          json.partial! 'api/v1/user/im/conversation_participants/conversation_participant', conversation_participant: message.conversation_participant

          json.abstract_user do
            json.partial! 'abstract_user', abstract_user: message.abstract_user
          end
        end
      end
    end
  end
end
