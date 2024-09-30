# frozen_string_literal: true

module RecordingJobs
  class VerifyTranscodedJob < ApplicationJob
    def perform
      return unless Ffprobe.installed?

      bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'])

      # transcoded recordings that were checked once and didn't pass access check
      Recording.where(status: :transcoded).where.not(error_reason: [nil, '']).find_each do |recording|
        url = bucket.object(recording.hls_main.gsub(%r{^/}, '')).public_url
        JSON.parse(Ffprobe.get_duration(url))
        recording.update(status: :done, error_reason: nil)
        RecordingMailer.ready(recording.id).deliver_later
      rescue JSON::ParserError
        recording.update(status: :error, error_reason: 'transcoded_check_error_2')
      end

      # transcoded recordings that are being checked for the first time
      Recording.where(status: :transcoded, error_reason: [nil, '']).find_each do |recording|
        url = bucket.object(recording.hls_main.gsub(%r{^/}, '')).public_url
        JSON.parse(Ffprobe.get_duration(url))
        recording.update(status: :done, error_reason: nil)
      rescue JSON::ParserError
        recording.update(error_reason: 'transcoded_check_error_1')
      end
    end
  end
end
