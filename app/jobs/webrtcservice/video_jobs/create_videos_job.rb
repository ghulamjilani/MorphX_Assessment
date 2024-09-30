# frozen_string_literal: true

module Webrtcservice
  module VideoJobs
    class CreateVideosJob < ApplicationJob
      def perform
        webrtcservice_client = Sender::Webrtcservice::Video.client
        compositions = webrtcservice_client.compositions_completed
        compositions.each do |composition|
          webrtcservice_room_info = webrtcservice_client.room(composition[:room_sid])
          webrtcservice_room = WebrtcserviceRoom.find_or_initialize_by(sid: webrtcservice_room_info[:sid], unique_name: webrtcservice_room_info[:unique_name])
          name_decoded = webrtcservice_room.decode_name
          next unless name_decoded[:current_service]

          video = ::Video.find_or_initialize_by(ffmpegservice_id: composition[:sid])
          next unless video.new_record?

          webrtcservice_control = Control::WebrtcserviceRoom.new(webrtcservice_room)

          video.room_id = name_decoded[:room_id]
          video.original_size = composition[:size]
          video.duration = composition[:duration].to_i * 1000
          video.ffmpegservice_download_url = webrtcservice_client.composition_media_url(composition[:sid])
          video.ffmpegservice_state = composition[:status]
          video.width, video.height = composition[:resolution].split('x')

          if (room = name_decoded[:room])
            video.status = ::Video::Statuses::FOUND
            video.user_id = room.presenter_user_id
          else
            video.status = ::Video::Statuses::ERROR
            video.error_reason = 'room_not_found'
            Airbrake.notify('Webrtcservice::Video::CreateVideosJob: Can not find video room',
                            parameters: {
                              name_decoded: name_decoded,
                              video: video.inspect,
                              composition: composition,
                              webrtcservice_room_info: webrtcservice_room_info
                            })
          end

          recordings = webrtcservice_control.layout_recordings(name_decoded[:room]&.session&.recording_layout)
          video.ffmpegservice_starts_at = if recordings.blank?
                                    DateTime.parse(composition[:date_created])
                                  else
                                    recordings.map { |recording| DateTime.parse(recording[:date_created]) }.min
                                  end.utc.to_fs(:rfc3339)
          video.save!
        rescue StandardError => e
          Airbrake.notify(e,
                          {
                            message: 'Failed to save webrtcservice composition',
                            composition: composition
                          })
        end
      rescue StandardError => e
        Airbrake.notify(e, { message: 'Failed to save webrtcservice compositions' })
      end
    end
  end
end
