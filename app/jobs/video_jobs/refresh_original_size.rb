# frozen_string_literal: true

class VideoJobs::RefreshOriginalSize < ApplicationJob
  def perform
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_VOD'])
    Video.where(original_size: [0, nil], deleted_at: nil).where.not(original_name: nil).find_each do |video|
      if video.user_id && video.room_id
        path = [video.s3_path, video.original_name].join('/').gsub(%r{^/}, '')
        object = bucket.object(path)
        video.update(original_size: object.content_length)
      end
    rescue StandardError => e
      Airbrake.notify(e, { message: 'Failed to update video original_size', video_id: video.id })
    end
  end
end
