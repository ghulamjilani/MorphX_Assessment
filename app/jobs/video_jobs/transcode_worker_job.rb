# frozen_string_literal: true

module VideoJobs
  class TranscodeWorkerJob < ApplicationJob
    sidekiq_options retry: false

    def perform(id)
      logger = Logger.new Rails.root.join("log/debug_video_transcode.#{Rails.env}.#{`hostname`.to_s.strip}.log")
      time_start = Time.now.utc
      logger_tag = "[#{time_start.to_i} | #{id}]"
      logger.info("#{logger_tag} worker start: #{time_start} [VideoJobs::TranscodeWorkerJob]")
      video = Video.find(id)
      unless video.status_ready_to_tr?
        logger.info("#{logger_tag} Error: not ready to be transcoded (#{video.status}) [VideoJobs::TranscodeWorkerJob]")
        return
      end

      bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD']) unless Rails.env.test? || Rails.env.development?

      video.storage_records.where(relation_type: %i[hls_main hls_preview]).find_each(&:destroy)

      video.update(status: Video::Statuses::TRANSCODING)
      s3_main_path = "#{video.s3_path}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s + video.id.to_s)}"
      s3_preview_path = "#{video.s3_path}/#{Digest::MD5.hexdigest(s3_main_path.to_s)}"

      video.s3_root = video.s3_path
      video.hls_preview = "#{s3_preview_path}/playlist.m3u8"

      video.hls_main = "#{s3_main_path}/playlist.m3u8"
      video.main_image_number = 3
      video.save!

      video.update(status: Video::Statuses::DONE) and return if Rails.env.development?

      original_url = if Rails.env.test?
                       nil
                     else
                       bucket.object("#{video.s3_path.gsub(%r{^/}, '')}/#{video.original_name}").public_url
                     end

      encode_params = {
        url: original_url,
        video_id: video.id,
        s3_preview_path: s3_preview_path,
        s3_main_path: s3_main_path,
        start_time: video.crop_seconds.to_i,
        duration: video.cropped_duration&.fdiv(1000) || (video.duration.fdiv(1000) - video.crop_seconds.to_i),
        width: video.width,
        height: video.height
      }

      job_id = Sender::Qencode.client.start_encode2(encode_params)

      TranscodeTask.create(job_id: job_id, transcodable: video, params: encode_params.to_json)

      time_end = Time.now.utc
      logger.info("#{logger_tag} End: #{time_end} | #{time_start} (#{time_end - time_start} seconds) [VideoJobs::TranscodeWorkerJob]")
    rescue ::Qencode::Errors::ServiceSuspendedError => e
      Airbrake.notify(e)
      video.update_columns(status: :ready_to_tr, error_reason: 'transcode_service_suspended')
    rescue StandardError => e
      logger.info("error: #{id}: #{e.message} [VideoJobs::TranscodeWorkerJob]")
      video.update_columns(status: :error, error_reason: 'transcode_worker_error')
      Airbrake.notify(e)
    end
  end
end
