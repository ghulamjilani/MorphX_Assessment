# frozen_string_literal: true

class Webhook::V1::FfmpegserviceController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def create
    data = params.to_unsafe_h
    debug_logger('ffmpegservice-webhook', data) unless Rails.env.test?

    if params[:object_type] == 'transcoder'
      case params[:event]
      when 'video.started'
        transcoder_video_started
      when 'stop.complete', 'video.stopped'
        transcoder_video_stopped
      end
    end

    head :ok
  end

  private

  def debug_logger(name, data = {})
    @custom_logger ||= Logger.new "#{Rails.root}/log/#{self.class.to_s.underscore.tr('/',
                                                                                     '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"
    @custom_logger.debug("[#{request&.remote_ip}]: #{name} | #{data}")
    puts "[#{self.class}][#{Time.now.utc}][#{request&.remote_ip}]: #{name} | #{data}"
  rescue StandardError => e
    Airbrake.notify(e)
  end

  def transcoder_video_started
    ffmpegservice_account&.stream_up!
  end

  def transcoder_video_stopped
    ffmpegservice_account&.stream_off!
  end

  def ffmpegservice_account
    return nil unless params[:object_type] == 'transcoder'

    @ffmpegservice_account ||= FfmpegserviceAccount.find_by(stream_id: params[:object_id])
  end
end
