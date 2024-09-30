# frozen_string_literal: true

module Webrtcservice
  module VideoJobs
    class CreateCompositionsJob < ApplicationJob
      def perform
        client = Sender::Webrtcservice::Video.client
        recordings = client.recordings_completed({ DateCreatedAfter: 1.week.ago.utc.to_fs(:rfc3339) })

        webrtcservice_room_sids = recordings.map { |r| r['grouping_sids']['room_sid'] }.uniq
        webrtcservice_room_sids.each_slice(5) do |chunk|
          chunk.each do |room_sid|
            room_data = client.room(room_sid)
            name_decoded = WebrtcserviceRoom.new(unique_name: room_data[:unique_name]).decode_name
            next unless name_decoded[:current_service] && name_decoded[:room]&.session

            session = name_decoded[:room].session
            webrtcservice_room = session.webrtcservice_rooms.find_or_create_by(sid: room_sid, unique_name: room_data[:unique_name])
            room_control = Control::WebrtcserviceRoom.new(webrtcservice_room)
            next unless webrtcservice_room && room_data[:status] == 'completed' && room_control.compositions.blank?

            layout = if session.recording_layout.include?('presenter') && room_control.presenter_participants.blank?
                       Webrtcservice::Video::Composition::Layouts::GRID
                     else
                       session.recording_layout
                     end
            room_control.create_composition(layout)
          end
          sleep 1
        end
      rescue StandardError => e
        Airbrake.notify(e, {
                          message: 'Failed to create compositions'
                        })
      end
    end
  end
end
