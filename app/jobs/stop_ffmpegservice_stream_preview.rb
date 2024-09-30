# frozen_string_literal: true

class StopFfmpegserviceStreamPreview < ApplicationJob
  def perform(stream_preview_id)
    clear_scheduled_jobs(stream_preview_id)

    stream_preview = StreamPreview.find_by(id: stream_preview_id)

    return unless stream_preview

    wa = stream_preview.ffmpegservice_account

    session_exists = wa.sessions.not_archived.not_cancelled.live_now.exists?
    if session_exists
      StopFfmpegserviceStreamPreview.perform_at(1.minute.from_now, stream_preview_id)
      send_websocket_wa_status(wa)
      return
    end

    unless wa.sandbox
      client = Sender::Ffmpegservice.client(account: wa)
      if (transcoder = client.stop_transcoder)
        if transcoder[:uptime_id].present?
          TranscoderUptime.find_or_create_by(streamable: stream_preview, transcoder_id: wa.stream_id,
                                             uptime_id: transcoder[:uptime_id])
        end
        client.transcoder_schedules.each do |schedule|
          if schedule[:action_type] == 'stop' && schedule[:recurrence_type] == 'once' && schedule[:stop_transcoder].to_time < stream_preview.end_at + 1.second
            client.delete_schedule(schedule[:id])
          end
        end
      end
    end
    stream_preview.stop!

    send_websocket_wa_status(wa)
  end

  private

  def clear_scheduled_jobs(stream_preview_id)
    ss = Sidekiq::ScheduledSet.new
    ss.select do |scheduled|
      ['StopFfmpegserviceStreamPreview',
       'FfmpegserviceAccountJobs::StreamPreviewStatus'].include?(scheduled.klass) && scheduled.args[0] == stream_preview_id
    end.map(&:delete)
  end

  def send_websocket_wa_status(wa)
    StreamPreviewsChannel.broadcast_to wa, { event: :stream_status, data: { stream_status: wa.stream_status } }
  end
end
