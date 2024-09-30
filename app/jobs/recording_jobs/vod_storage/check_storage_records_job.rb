# frozen_string_literal: true

module RecordingJobs
  module VodStorage
    class CheckStorageRecordsJob < ApplicationJob
      def perform(recording_id)
        return if Rails.env.test? || Rails.env.development?

        @recording = Recording.find(recording_id)
        update_existing_records
        check_hls_records
      rescue StandardError => e
        Airbrake.notify(e, { message: 'Failed to check recording storage records', recording_id: })
      end

      def update_existing_records
        @recording.storage_records.find_each(&:refresh_record)
      end

      def check_hls_records
        s3_root_path = @recording.s3_root_path.gsub(%r{^/}, '')
        paths = %i[hls_main hls_preview]
        paths.each do |relation_type|
          match = @recording.send(relation_type).to_s.match(%r{(#{s3_root_path}/[^/]+)})
          next if match.blank?

          path = match[1]
          next if path.blank?
          next if Storage::Record.exists?(model: @recording, object_id: path)

          storage_record = @recording.storage_records.new(
            relation_type: relation_type,
            object_id: path,
            object_type: 'Aws::S3::ObjectSummary::Collection',
            s3_bucket_name: ENV['S3_BUCKET_VOD']
          )

          storage_record.save if storage_record.manager.object_exists?
        end
      end
    end
  end
end
