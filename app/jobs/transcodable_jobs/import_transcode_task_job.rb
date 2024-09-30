# frozen_string_literal: true

module TranscodableJobs
  class ImportTranscodeTaskJob < ApplicationJob
    def perform(job_id, id, klass = 'Video')
      return if TranscodeTask.exists?(job_id:)
      return unless (transcodable = klass.classify.constantize.find_by(id:))

      transcode_task = TranscodeTask.new(job_id: job_id, transcodable: transcodable, params: task_params(transcodable))
      task_control = Control::TranscodeTask.new(transcode_task)
      task_control.update_status
    end

    def task_params(transcodable)
      original_url = if Rails.env.test? || Rails.env.development?
                       nil
                     elsif transcodable.is_a?(Recording)
                       Rails.application.routes.url_helpers.url_for(recording.file)
                     elsif transcodable.is_a?(Video)
                       bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'])
                       bucket.object("#{video.s3_path.gsub(%r{^/}, '')}/#{video.original_name}").public_url
                     else
                       raise(ArgumentError, "unsupported transcodable type '#{transcodable.class}'")
                     end

      { url: original_url,
        video_id: transcodable.id,
        start_time: transcodable.crop_seconds.to_i,
        duration: transcodable.cropped_duration&.fdiv(1000) || transcodable.duration.fdiv(1000),
        width: transcodable.width,
        height: transcodable.height }.to_json
    end
  end
end
