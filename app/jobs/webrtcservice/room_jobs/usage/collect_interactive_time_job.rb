# frozen_string_literal: true

module Webrtcservice
  module RoomJobs
    module Usage
      class CollectInteractiveTimeJob < ApplicationJob
        def perform(webrtcservice_room_id)
          return unless (webrtcservice_room = ::WebrtcserviceRoom.find_by(id: webrtcservice_room_id))
          return unless (session = webrtcservice_room.session)

          time_now = Time.now.utc
          room_participants = Sender::Webrtcservice::Video.client.room_participants(webrtcservice_room.sid)

          room_participants.each do |room_participant|
            identity = Webrtcservice::Video::Participant.decode_identity(room_participant[:identity])
            user = User.find_by(id: identity[:id])
            messages = [
              {
                channel_id: session.channel_id,
                client_type: ::Usage::Client::Types::API,
                event_time: time_now.to_i,
                event_type: ::Usage::Event::Types::INTERACTIVE_TIME,
                event_value: room_participant[:duration],
                host_id: session.organizer.id,
                model_id: session.id,
                model_type: session.class.name,
                organization_id: session.organization_id
              }
            ]

            Sender::Usage::EventReceiver.client(user).user_messages(messages)
          end
        rescue StandardError => e
          Airbrake.notify(e, { message: 'Failed to remove room participant' })
        end
      end
    end
  end
end
