# frozen_string_literal: true

module Control
  class WebrtcserviceRoom
    attr_reader :sid

    def initialize(webrtcservice_room)
      @webrtcservice_room = webrtcservice_room || WebrtcserviceRoom.new
      @webrtcservice_room.validate
      @sid = @webrtcservice_room.sid
    end

    def compositions(params = {})
      @compositions ||= client.room_compositions(sid, params)
    end

    def participants
      @participants ||= client.room_participants(sid, { expected_status: [200, 404] })
    end

    def presenter_participants
      @presenter_participants ||= participants.filter do |participant|
        JSON.parse(participant[:identity])['rl'] == ::Webrtcservice::Video::Participant::RoleCodes::PRESENTER
      rescue JSON::ParserError
        false
      end
    end

    def presenter_participant_sids
      @presenter_participant_sids ||= presenter_participants.pluck(:sid)
    end

    def presenter_connected?
      presenter_participants.filter { |participant| participant[:status] == 'connected' }.present?
    end

    def user_participants
      @user_participants ||= participants.filter do |participant|
        JSON.parse(participant[:identity])['rl'] != ::Webrtcservice::Video::Participant::RoleCodes::PRESENTER
      rescue JSON::ParserError
        false
      end
    end

    def user_participant_sids
      @user_participant_sids ||= user_participants.pluck(:sid)
    end

    def recordings
      @recordings ||= client.room_recordings(sid, { expected_status: [200, 404] })
    end

    def layout_recordings(layout = nil)
      layout = layout || @webrtcservice_room.recording_layout || ::Webrtcservice::Video::Composition::Layouts::GRID

      return recordings unless [::Webrtcservice::Video::Composition::Layouts::PRESENTER_ONLY, ::Webrtcservice::Video::Composition::Layouts::PRESENTER_FOCUS].include?(layout)

      case layout
      when ::Webrtcservice::Video::Composition::Layouts::PRESENTER_ONLY
        recordings.filter { |recording| presenter_participant_sids.include?(recording[:grouping_sids][:participant_sid]) }
      when ::Webrtcservice::Video::Composition::Layouts::PRESENTER_FOCUS
        recordings.filter { |recording| presenter_participant_sids.include?(recording[:grouping_sids][:participant_sid]) || recording[:type] == 'audio' }
      else
        recordings
      end
    rescue StandardError => e
      Airbrake.notify(e)
      recordings
    end

    def create_composition(layout = nil)
      layout = layout || @webrtcservice_room.recording_layout || ::Webrtcservice::Video::Composition::Layouts::GRID
      layout_params = ::Webrtcservice::Video::Composition.layout_parameters(layout:, presenter_sids: presenter_participant_sids, user_sids: user_participant_sids)
      client.create_composition(sid, layout_params)
    end

    def complete_room
      room_data = client.complete_room((sid || @webrtcservice_room.unique_name), { expected_status: [200, 202, 404] })
      sync_room(room_data)
    end

    def sync_room(room_data)
      @webrtcservice_room.update(mapped_response_attributes(room_data))
    end

    def delete_recordings
      recordings.filter { |recording| recording[:status] == 'completed' }.each_slice(5) do |chunk|
        chunk.each do |recording|
          client.delete_recording(recording[:sid])
        end
        sleep 1
      end
    end

    private

    def mapped_response_attributes(room_data)
      return {} if room_data.blank?

      {
        sid: room_data[:sid],
        unique_name: room_data[:unique_name],
        status: room_data[:status],
        ended_at: room_data[:end_time],
        max_participants: room_data[:max_participants],
        record_enabled: room_data[:record_participants_on_connect]
      }.compact
    end

    def client
      @client ||= Sender::Webrtcservice::Video.client
    end
  end
end
