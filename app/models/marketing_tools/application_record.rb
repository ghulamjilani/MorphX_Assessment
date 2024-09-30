# frozen_string_literal: true

module MarketingTools
  class ApplicationRecord < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection
    include ModelConcerns::ActiveModel::Extensions

    self.abstract_class = true
    self.table_name_prefix = 'mrk_tools_'
  end
end
