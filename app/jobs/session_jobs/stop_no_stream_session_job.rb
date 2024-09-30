# frozen_string_literal: true

module SessionJobs
  class StopNoStreamSessionJob < ApplicationJob
    def perform(session_id)
      debug_logger('start', { session: session_id })

      unless (session = Session.find_by(id: session_id))
        debug_logger('no session', { session: session_id }) and return
      end

      unless (wa = session.ffmpegservice_account)
        debug_logger('no ffmpegservice account', { session: session_id, wa: session.ffmpegservice_account_id }) and return
      end

      unless (room = session.room)
        debug_logger('no room', { session: session_id }) and return
      end

      begin
        connected = Sender::Ffmpegservice.client(account: wa).stats_transcoder[:connected][:value].to_s.casecmp('yes').zero?
      rescue StandardError => e
        Airbrake.notify(e, { session: session_id, room: room.id, wa: wa.id })
        debug_logger('no response from ffmpegservice?', { session: session_id, room: room.id, wa: wa.id, message: e.message })
        SessionJobs::StopNoStreamSessionJob.perform_at(10.seconds.from_now, session_id)
        return
      end

      if connected
        debug_logger('connected', { session: session_id })
        return
      end

      debug_logger('STOP', { session: session_id, room: room.id, wa: wa.id })
      Control::Room.new(room).stop
      session.update_columns(stop_reason: 'no_stream_autostop')
    end
  end
end
