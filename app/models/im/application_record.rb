# frozen_string_literal: true

module Im
  class ApplicationRecord < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection
    include ModelConcerns::ActiveModel::Extensions

    self.abstract_class = true
    self.table_name_prefix = 'im_'
  end
end
