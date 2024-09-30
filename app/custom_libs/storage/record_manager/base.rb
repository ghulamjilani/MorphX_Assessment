# frozen_string_literal: true

module Storage
  module RecordManager
    class Base
      attr_accessor :storage_record

      METHODS_TO_INHERIT = %w[object_byte_size object_exists? remove_object].freeze

      METHODS_TO_INHERIT.each do |method_name|
        define_method(method_name) { raise NotIngeritedError }
      end

      def initialize(storage_record)
        @storage_record = storage_record
      end

      def refresh_object_size
        byte_size = object_byte_size
        storage_record.update(byte_size:) unless byte_size.nil?
      end

      def refresh_record
        if object_exists?
          refresh_object_size
        else
          # storage_record.destroy
          Airbrake.notify(
            'Storage::Record object not found',
            {
              model_type: storage_record.model_type,
              model_id: storage_record.model_id,
              relation_type: storage_record.relation_type,
              storage_record_id: storage_record.id,
              object_type: storage_record.object_type,
              object_id: storage_record.object_id
            }
          )
        end
      end

      def logger
        @logger ||= Logger.new(Rails.root.join("log/#{self.class.to_s.underscore.tr('/', '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"))
      end
    end
  end
end
