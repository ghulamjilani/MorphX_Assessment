# frozen_string_literal: true

module ModelConcerns
  # # ActiveModel::Errors requires @errors definition:
  # def initialize
  #   @errors = ActiveModel::Errors.new(self)
  # end
  module Mongoid
    module HasColumnNames
      extend ActiveSupport::Concern

      module ClassMethods
        def column_names
          attribute_names
        end
      end
    end
  end
end
