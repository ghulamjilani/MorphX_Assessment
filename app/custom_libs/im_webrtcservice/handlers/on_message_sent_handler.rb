# frozen_string_literal: true

module ImWebrtcservice
  module Handlers
    module OnMessageSentHandler
      class << self
        def event_type
          'onMessageSent'
        end

        def process(params:)
          client = Webrtcservice::REST::Client.new(ENV['webrtcservice_ACCOUNT_SID'], ENV['webrtcservice_AUTH_TOKEN'])
          channel = ChatChannel.find_by!(webrtcservice_id: params[:ChannelSid])
          webrtcservice_message =
            client
            .chat
            .services(ENV['webrtcservice_CHAT_SID'])
            .channels(channel.webrtcservice_id)
            .messages(params[:MessageSid])
            .fetch

          ChatMessage.create(
            user_id: webrtcservice_message.from,
            user_type: begin
              (JSON.parse(webrtcservice_message.body)['authorType'] || 'User')
            rescue StandardError
              'User'
            end,
            position: webrtcservice_message.index,
            webrtcservice_id: webrtcservice_message.sid,
            body: webrtcservice_message.body,
            created_at: webrtcservice_message.date_created,
            updated_at: webrtcservice_message.date_updated,
            edited: webrtcservice_message.was_edited,
            last_updated_by: webrtcservice_message.last_updated_by,
            chat_channel: channel
          )
        end
      end
    end
  end
end
