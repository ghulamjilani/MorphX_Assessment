# frozen_string_literal: true

class StopFfmpegserviceStream < ApplicationJob
  sidekiq_options queue: :critical

  def perform(ffmpegservice_account_id)
    debug_logger('stop stream', ffmpegservice_account_id)

    wa = FfmpegserviceAccount.find_by(id: ffmpegservice_account_id)
    return unless wa

    debug_logger('stopping stream',
                 { ffmpegservice_account_id: ffmpegservice_account_id, stream_id: wa.stream_id, sandbox: wa.sandbox })

    unless wa.sandbox
      Sender::Ffmpegservice.client(account: wa).stop_stream
    end
    wa.stream_off!
  end
end
