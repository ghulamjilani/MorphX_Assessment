# frozen_string_literal: true

module Storage
  module RecordManager
    module Local
      class ActiveStorageAttachment < Storage::RecordManager::Base
        def object_byte_size
          storage_record.object.byte_size
        rescue StandardError => e
          Airbrake.notify(e)
          nil
        end

        def object_exists?
          storage_record.blob_exists?
        end

        def remove_object
          logger.info "remove_object id: #{storage_record.id}, model: #{storage_record.model_type} ##{storage_record.model_id}, relation: #{storage_record.relation_type}"
          if storage_record.model.blank?
            logger.info "#{storage_record.model_type} ##{storage_record.model_id} not found!"
            return
          end

          storage_record.model.send(storage_record.relation_type)&.purge
        end
      end
    end
  end
end
