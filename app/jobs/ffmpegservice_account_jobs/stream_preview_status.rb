# frozen_string_literal: true

class FfmpegserviceAccountJobs::StreamPreviewStatus < ApplicationJob
  def perform(stream_preview_id)
    stream_preview = StreamPreview.find(stream_preview_id)
    clear_scheduled_status(stream_preview_id)

    wa = stream_preview.ffmpegservice_account
    return unless wa

    unless wa.sandbox
      wa_client = Sender::Ffmpegservice.client(account: wa)
      ss = wa_client.state_stream
      state = ss[:state]
      wa.host_ip = ss[:ip_address] if wa.host_ip != ss[:ip_address]
      wa.stream_off!        if state == 'stopped' && !wa.stream_off?
      wa.stream_starting!   if state == 'starting' && !wa.stream_starting?
      if state == 'started'
        if wa_client.stream_active?
          wa.stream_up! unless wa.stream_up?
        else
          wa.stream_down! unless wa.stream_down?
        end
      end
    end

    StreamPreviewsChannel.broadcast_to wa, { event: :stream_status, data: { stream_status: wa.stream_status } }

    stop_at = stream_preview.end_at + 1.minute
    if !stream_preview.stopped? && Time.now < stop_at
      FfmpegserviceAccountJobs::StreamPreviewStatus.perform_at((wa.stream_up? ? 30 : 10).seconds.from_now, stream_preview_id)
    end
  end

  private

  def clear_scheduled_status(stream_preview_id)
    ss = Sidekiq::ScheduledSet.new
    ss.select do |scheduled|
      scheduled.klass == 'FfmpegserviceAccountJobs::StreamPreviewStatus' &&
        scheduled.args[0] == stream_preview_id
    end.map(&:delete)
  end
end
