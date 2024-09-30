# frozen_string_literal: true

module VideoJobs
  class VerifyTranscodedJob < ApplicationJob
    def perform
      return unless Ffprobe.installed?

      bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'])

      # transcoded videos that were checked once and didn't pass access check
      Video.where(status: Video::Statuses::TRANSCODED).where.not(error_reason: [nil, '']).find_each do |video|
        url = bucket.object(video.hls_main.gsub(%r{^/}, '')).public_url

        JSON.parse(Ffprobe.get_duration(url))
        video.update(status: Video::Statuses::DONE, error_reason: nil)
        VideoMailer.ready(video.id).deliver_later if video.session&.do_record?
      rescue JSON::ParserError
        video.update(status: Video::Statuses::ERROR, error_reason: 'transcoded_check_error_2')
      end

      # transcoded videos that are being checked for the first time
      Video.where(status: Video::Statuses::TRANSCODED, error_reason: [nil, '']).find_each do |video|
        url = bucket.object(video.hls_main.gsub(%r{^/}, '')).public_url

        JSON.parse(Ffprobe.get_duration(url))
        video.update(status: Video::Statuses::DONE, error_reason: nil)
      rescue JSON::ParserError
        video.update(error_reason: 'transcoded_check_error_1')
      end
    end
  end
end
