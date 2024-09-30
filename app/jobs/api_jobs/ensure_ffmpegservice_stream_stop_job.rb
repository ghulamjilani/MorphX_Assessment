# frozen_string_literal: true

module ApiJobs
  class EnsureFfmpegserviceStreamStopJob < ApplicationJob
    sidekiq_options queue: :critical

    def perform(room_id)
      debug_logger('Job start', room_id)
      room = Room.find_by(id: room_id)

      return if room.blank? || !room.ffmpegservice? || room.ffmpegservice_account.blank?

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

      active_room_ids = Room.with_open_lobby.not_closed.not_cancelled.joins(:session).where.not(id: room_id).where(sessions: { ffmpegservice_account_id: wa.id, stopped_at: nil }).pluck(:id)

      client = Sender::Ffmpegservice.client(account: wa)
      transcoder_state = client.state_transcoder.to_h.with_indifferent_access

      if transcoder_state[:uptime_id].present?
        TranscoderUptime.find_or_create_by(streamable: room, transcoder_id: wa.stream_id,
                                           uptime_id: transcoder_state[:uptime_id])
      end

      if active_room_ids.present?
        debug_logger('another room using this livestream is active, reset livestream',
                     { room_id: room_id, active_room_ids: active_room_ids, transcoder_state: transcoder_state })
        if (response = client.reset_transcoder).present?
          debug_logger('successfull reset transcoder request', { room_id: room_id, transcoder_id: wa.stream_id, response: response })
          return true
        end

        # didn't get response for reset transcoder request, retry in 15 seconds
        debug_logger('request to reset transcoder failed, retry in 15 seconds', { room_id: room_id, transcoder_id: wa.stream_id })
        ApiJobs::EnsureFfmpegserviceStreamStopJob.perform_at(15.seconds.from_now, room_id)
        return
      end

      case transcoder_state[:state]
      when 'started'
        debug_logger('transcoder is ready to stop', { room_id: room_id, state: transcoder_state })
      when 'stopped', 'resetting'
        debug_logger('transcoder is already stopped or is resetting', { room_id: room_id, state: transcoder_state })
        return true
      else
        debug_logger('transcoder is not ready to stop, retry in 15 seconds',
                     { room_id: room_id, state: transcoder_state })
        ApiJobs::EnsureFfmpegserviceStreamStopJob.perform_at(15.seconds.from_now, room_id)
        return
      end

      response = client.stop_transcoder

      if response.present?
        debug_logger('stop_transcoder_response', { room_id: room_id, transcoder_id: wa.stream_id, response: response })
        if response[:uptime_id].present?
          TranscoderUptime.find_or_create_by(streamable: room, transcoder_id: wa.stream_id,
                                             uptime_id: response[:uptime_id])
        end
        return true
      end

      debug_logger('request to stop transcoder failed, retry in 15 seconds',
                   { room_id: room_id, transcoder_id: wa.stream_id })
      ApiJobs::EnsureFfmpegserviceStreamStopJob.perform_at(15.seconds.from_now, room_id)
      nil
    rescue StandardError => e
      Airbrake.notify(e, { room_id: room_id })
      nil
    end
  end
end
