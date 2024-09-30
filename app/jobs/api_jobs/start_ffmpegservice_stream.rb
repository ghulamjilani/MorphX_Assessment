# frozen_string_literal: true

module ApiJobs
  class StartFfmpegserviceStream < ApplicationJob
    sidekiq_options queue: :critical

    def perform(room_id, _manual = nil)
      debug_logger('START LIVESTREAM', room_id)
      room = Room.find_by(id: room_id)

      return if room.blank? || room.closed? || !room.ffmpegservice? || room.ffmpegservice_account.blank?
      return if Time.now > room.actual_end_at || room.abstract_session.stopped_at.present?
      return if room.abstract_session.cancelled?

      wa = room.ffmpegservice_account
      debug_logger('room info', {
                     room: {
                       id: room_id,
                       actual_start_at: room.actual_start_at,
                       actual_end_at: room.actual_end_at,
                       status: room.status
                     },
                     ffmpegservice_account: {
                       id: wa.id,
                       stream_id: wa.stream_id,
                       stream_status: wa.stream_status
                     }
                   })

      client = Sender::Ffmpegservice.client(account: wa)
      transcoder_state = client.state_transcoder.to_h.with_indifferent_access

      case transcoder_state[:state]
      when 'started', 'starting'
        debug_logger('livestream has already started', { room_id: room_id, state: transcoder_state })
        ping_and_unchain(room)
        return true
      when 'stopped'
        debug_logger('livestream is ready to start', { room_id: room_id, state: transcoder_state })
      else
        debug_logger('livestream is not ready to start, retry in 15 seconds',
                     { room_id: room_id, state: transcoder_state })
        ApiJobs::StartFfmpegserviceStream.perform_at(15.seconds.from_now, room_id)
        return
      end

      response = client.start_stream

      if response[:live_stream].present?
        debug_logger('livestream started successfully', { room_id: room_id })
        if (uptime_id = ApiJobs::RoomTranscoderUptimeJob.new.perform(room_id))
          debug_logger('transcoder_uptime',
                       { room_id: room_id, transcoder_id: wa.stream_id,
                         uptime_id: uptime_id })
        end
        ping_and_unchain(room)
        return true
      end

      debug_logger('request to start livestream failed, retry in 15 seconds',
                   { room_id: room_id, transcoder_id: wa.stream_id })
      ApiJobs::StartFfmpegserviceStream.perform_at(15.seconds.from_now, room_id)
      nil
    rescue StandardError => e
      Airbrake.notify(e, { room_id: room_id })
    end

    def ping_and_unchain(room)
      unless SidekiqSystem::Schedule.exists?(SessionJobs::PingLivestream, room.id)
        SessionJobs::PingLivestream.perform_at(10.seconds.from_now, room.id)
      end

      if room.abstract_session_type == 'Session'
        room.abstract_session.unchain_all!
      end
    end
  end
end
