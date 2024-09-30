# frozen_string_literal: true

module ModelConcerns
  module Shared
    module HasStorageRecords
      extend ActiveSupport::Concern

      included do
        has_many :storage_records, class_name: 'Storage::Record', as: :model, dependent: :destroy
      end
    end
  end
end
