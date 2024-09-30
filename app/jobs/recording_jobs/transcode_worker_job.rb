# frozen_string_literal: true

module RecordingJobs
  class TranscodeWorkerJob < ApplicationJob
    sidekiq_options retry: false

    def perform(id)
      logger = Logger.new Rails.root.join("log/debug_recording_transcode.#{Rails.env}.#{`hostname`.to_s.strip}.log")
      time_start = Time.now.utc
      logger_tag = "[#{time_start.to_i} | #{id}]"
      logger.info("#{logger_tag} worker start: #{time_start} [RecordingJobs::TranscodeWorkerJob]")
      recording = Recording.find(id)
      unless recording.ready_to_tr?
        logger.info("#{logger_tag} Error: not ready to be transcoded (#{recording.status}) [RecordingJobs::TranscodeWorkerJob]")
        return
      end

      recording.storage_records.where(relation_type: %i[hls_main hls_preview]).find_each(&:destroy)

      recording.transcoding!
      s3_main_path = "#{recording.s3_root_path}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s + recording.id.to_s)}"
      s3_preview_path = "#{recording.s3_root_path}/#{Digest::MD5.hexdigest(s3_main_path.to_s)}"

      recording.s3_root = recording.s3_root_path

      recording.hls_preview = "#{s3_preview_path}/playlist.m3u8"
      url = if Rails.env.test?
              nil
            else
              # Rails.application.routes.url_helpers.url_for(recording.file)
              recording.file.url
            end

      if recording.width.to_i.zero? || recording.height.to_i.zero? || recording.duration.to_i.zero?
        begin
          analyzer = ActiveStorage::Analyzer::VideoAnalyzer.new(recording.file.blob).metadata
          recording.width = analyzer[:width].to_i
          recording.height = analyzer[:height].to_i
          recording.duration = (analyzer[:duration].to_f * 1000).to_i
          recording.original_size = recording.file.byte_size
          recording.update_columns(error_reason: 'trw_analyzer_no_source') if !analyzer[:video] || !analyzer[:audio]
        rescue StandardError
          recording.width = recording.height = nil
        end
      end

      recording.hls_main = "#{s3_main_path}/playlist.m3u8"
      recording.main_image_number = 3
      recording.save!

      recording.done! and return if Rails.env.development?

      encode_params = {
        url: url.to_s,
        callback_url: "#{ENV['PROTOCOL']}#{ENV['HOST']}/webhook/v1/qencode/recording",
        video_id: recording.id,
        s3_preview_path: s3_preview_path,
        s3_main_path: s3_main_path,
        start_time: recording.crop_seconds.to_i,
        duration: recording.cropped_duration&.fdiv(1000) || (recording.duration.fdiv(1000) - recording.crop_seconds.to_i),
        width: recording.width,
        height: recording.height
      }

      job_id = Sender::Qencode.client.start_encode2(encode_params)

      TranscodeTask.create(job_id: job_id, transcodable: recording, params: encode_params.to_json)

      time_end = Time.now.utc
      logger.info("#{logger_tag} End: #{time_end} | #{time_start} (#{time_end - time_start} seconds) [RecordingJobs::TranscodeWorkerJob]")
    rescue ::Qencode::Errors::ServiceSuspendedError => e
      Airbrake.notify(e)
      recording.update_columns(status: :ready_to_tr, error_reason: 'transcode_service_suspended')
    rescue StandardError => e
      logger.info("error: #{id}: #{e.message} [RecordingJobs::TranscodeWorkerJob]")
      recording.update_columns(status: :error, error_reason: 'transcode_worker_error')
      Airbrake.notify(e)
    end
  end
end
