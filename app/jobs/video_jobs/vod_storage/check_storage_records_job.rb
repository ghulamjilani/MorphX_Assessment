# frozen_string_literal: true

module VideoJobs
  module VodStorage
    class CheckStorageRecordsJob < ApplicationJob
      def perform(video_id)
        @video = Video.find(video_id)
        update_existing_records
        check_original_file
        check_hls_records
        create_missing_records
      rescue StandardError => e
        Airbrake.notify(e, { message: 'Failed to update video size', video_id: })
      end

      def update_existing_records
        @video.storage_records
              .where(object_type: ::Storage::ObjectTypes::S3)
              .find_each(&:refresh_record)
      end

      def check_original_file
        return if @video.original_path.blank?
        return if Storage::Record.exists?(model: @video, object_id: @video.original_path)

        storage_record = @video.storage_records.new(
          relation_type: :file,
          object_id: @video.original_path,
          object_type: 'Aws::S3::ObjectSummary::Collection',
          s3_bucket_name: ENV['S3_BUCKET_VOD']
        )

        storage_record.save if storage_record.manager.object_exists?
      end

      def check_hls_records
        s3_root_path = @video.s3_path.gsub(%r{^/}, '')
        paths = %i[hls_main hls_preview]
        paths.each do |relation_type|
          match = @video.send(relation_type).to_s.match(%r{(#{s3_root_path}/[^/]+)})
          next if match.blank?

          path = match[1]
          next if path.blank?
          next if Storage::Record.exists?(model: @video, object_id: path)

          storage_record = @video.storage_records.new(
            relation_type: relation_type,
            object_id: path,
            object_type: 'Aws::S3::ObjectSummary::Collection',
            s3_bucket_name: ENV['S3_BUCKET_VOD']
          )

          storage_record.save if storage_record.manager.object_exists?
        end
      end

      def create_missing_records
        video_root_objects.each do |object_name|
          next if Storage::Record.exists?(model: @video, object_id: object_name)

          @video.storage_records.create(
            relation_type: 'found',
            object_id: object_name,
            object_type: 'Aws::S3::ObjectSummary::Collection',
            s3_bucket_name: ENV['S3_BUCKET_VOD']
          )
        end
      end

      def video_root_objects
        return [] if Rails.env.test? || Rails.env.development?

        s3_root_path = @video.s3_path.gsub(%r{^/}, '')
        bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'])
        bucket.objects({ prefix: s3_root_path }).map do |object|
          # "67920/6237/465b65f9f955de998b72ed1b4ea3668e/audio_0_1/segment-9.ts" => "67920/6237/465b65f9f955de998b72ed1b4ea3668e"
          object.key.match(%r{(#{s3_root_path}/[^/]+)})[1]
        end.uniq
      end
    end
  end
end
