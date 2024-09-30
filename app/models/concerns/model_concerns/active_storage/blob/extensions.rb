# frozen_string_literal: true

module ModelConcerns
  module ActiveStorage
    module Blob
      module Extensions
        extend ActiveSupport::Concern

        included do
          has_many :storage_records, class_name: 'Storage::Record', inverse_of: :blob, foreign_key: :blob_id, dependent: :destroy
        end
      end
    end
  end
end
