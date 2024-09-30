# frozen_string_literal: true

module VideoJobs
  class VerifyOriginalJob < ApplicationJob
    def perform
      return unless Ffprobe.installed?

      bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'])

      # downloaded videos that were checked once and didn't pass access check
      Video.where(status: Video::Statuses::DOWNLOADED).where.not(error_reason: [nil, '']).find_each do |video|
        url = bucket.object("#{video.s3_path.gsub(%r{^/}, '')}/#{video.original_name}").public_url

        JSON.parse(Ffprobe.get_duration(url))
        video.update(status: Video::Statuses::ORIGINAL_VERIFIED, error_reason: nil)
      rescue JSON::ParserError
        video.update(status: Video::Statuses::ERROR, error_reason: 'original_check_error_2')
      end

      # videos that are being checked for the first time
      Video.where(status: Video::Statuses::DOWNLOADED, error_reason: [nil, '']).find_each do |video|
        url = bucket.object("#{video.s3_path.gsub(%r{^/}, '')}/#{video.original_name}").public_url

        JSON.parse(Ffprobe.get_duration(url))
        video.update(status: Video::Statuses::ORIGINAL_VERIFIED, error_reason: nil)
      rescue JSON::ParserError
        video.update(error_reason: 'original_check_error_1')
      end
    end
  end
end
