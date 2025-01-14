# frozen_string_literal: true

class Partner
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'partner_'
  end
end
