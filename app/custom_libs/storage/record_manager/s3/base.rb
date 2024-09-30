# frozen_string_literal: true

module Storage
  module RecordManager
    module S3
      class Base < Storage::RecordManager::Base
        def bucket_object
          @bucket_object ||= bucket.object(storage_record.object_id)
        end

        def bucket_object_collection
          return [] if Rails.env.test? || Rails.env.development?

          @bucket_object_collection ||= bucket.objects({ prefix: storage_record.object_id })
        end

        def bucket
          @bucket ||= Aws::S3::Resource.new.bucket(storage_record.s3_bucket_name) # ENV['S3_BUCKET_VOD']
        end
      end
    end
  end
end
