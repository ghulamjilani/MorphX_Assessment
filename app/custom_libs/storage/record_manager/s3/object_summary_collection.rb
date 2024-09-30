# frozen_string_literal: true

module Storage
  module RecordManager
    module S3
      class ObjectSummaryCollection < Storage::RecordManager::S3::Base
        def object_byte_size
          total_size = 0
          bucket_object_collection.each do |obj|
            total_size += obj.content_length # Size of the body in bytes.
          end
          total_size
        rescue StandardError => e
          Airbrake.notify(e)
          nil
        end

        def object_exists?
          return true if Rails.env.test? || Rails.env.development?

          bucket_object_collection.count.positive?
        end

        def remove_object
          logger.info "remove_object id: #{storage_record.id}, model: #{storage_record.model_type} ##{storage_record.model_id}, relation: #{storage_record.relation_type}"
          return true if Rails.env.test? || Rails.env.development?

          bucket_object_collection.batch_delete!
        end
      end
    end
  end
end
