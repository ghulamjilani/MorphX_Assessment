# frozen_string_literal: true

module ModelConcerns
  # # ActiveModel::Errors requires @errors definition:
  # def initialize
  #   @errors = ActiveModel::Errors.new(self)
  # end
  module HasErrors
    extend ActiveSupport::Concern
    extend ::ActiveModel::Naming

    included do
      attr_reader :errors
      attr_accessor :name

      # The following three methods are needed to be
      # minimally implemented for +Errors+ to be
      # able to generate error messages correctly

      def read_attribute_for_validation(attr)
        send(attr)
      end

      def self.human_attribute_name(attr, _options = {})
        attr
      end

      def self.lookup_ancestors
        [self]
      end
    end
  end
end
