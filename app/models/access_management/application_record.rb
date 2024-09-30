# frozen_string_literal: true

class AccessManagement::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'access_management_'
end
