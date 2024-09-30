# frozen_string_literal: true

module Storage
  class RecordManagerFactory
    class << self
      def create(storage_record)
        case storage_record.object_type
        when Storage::ObjectTypes::S3_COLLECTION
          ::Storage::RecordManager::S3::ObjectSummaryCollection.new(storage_record)
        when Storage::ObjectTypes::LOCAL_ATTACHMENT
          ::Storage::RecordManager::Local::ActiveStorageAttachment.new(storage_record)
        else
          raise "unsupported storage object type #{storage_record.object_type}"
        end
      end
    end
  end
end
