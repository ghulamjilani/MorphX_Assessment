# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  self.abstract_class = true
end
