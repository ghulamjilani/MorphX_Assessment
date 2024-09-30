# frozen_string_literal: true

module Storage
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'storage_'
  end
end
