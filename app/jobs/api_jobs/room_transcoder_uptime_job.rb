# frozen_string_literal: true

module ApiJobs
  class RoomTranscoderUptimeJob < ApplicationJob
    def perform(room_id)
      room = Room.find_by(id: room_id)

      debug_logger('start', { room_id: room_id })

      return if room.blank? || room.closed? || !room.ffmpegservice? || room.ffmpegservice_account.blank?
      return if Time.now < room.actual_start_at || Time.now > room.actual_end_at || room.abstract_session.stopped?

      wa = room.ffmpegservice_account
      client = Sender::Ffmpegservice.client(account: wa)

      if (transcoder = client.state_transcoder.to_h.with_indifferent_access) && transcoder[:uptime_id].present?
        debug_logger('transcoder_uptime received',
                     { room_id: room.id, transcoder_id: wa.stream_id, uptime_id: transcoder[:uptime_id],
                       state: transcoder[:state] })
        TranscoderUptime.find_or_create_by(streamable: room, transcoder_id: wa.stream_id,
                                           uptime_id: transcoder[:uptime_id])
        return transcoder[:uptime_id]
      else
        debug_logger('transcoder_uptime empty, retry in 15 seconds', { room_id: room.id, transcoder_id: wa.stream_id })
        ApiJobs::RoomTranscoderUptimeJob.perform_at(15.seconds.from_now, room_id)
      end

      nil
    end
  end
end
