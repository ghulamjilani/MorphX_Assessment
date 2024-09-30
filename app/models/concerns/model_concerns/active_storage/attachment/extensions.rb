# frozen_string_literal: true

module ModelConcerns
  module ActiveStorage
    module Attachment
      module Extensions
        extend ActiveSupport::Concern

        included do
          after_create_commit :create_storage_record
        end

        def create_storage_record
          ::Storage::Record.create(model: record, relation_type: name, object_id: id, object_type: self.class.name, blob_id: blob_id)
        end
      end
    end
  end
end
