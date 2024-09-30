# frozen_string_literal: true
module ModelConcerns
  module Mongoid
    module ActiveRecordBridge
      extend ActiveSupport::Concern

      included do
        def self.belongs_to_record(association_name, options = {})
          association_class = options[:class_name] || association_name.to_s.singularize.classify
          association_class = 'User'
          class_eval %<
          field :#{association_name}_id, type: Integer
          #{"field :#{association_name}_type, type: String" if options[:polymorphic].present?}

          index(#{association_name}_id: 1)

          def #{association_name}
            @#{association_name}_class ||= #{association_name}_type.present? ? #{association_name}_type.constantize : #{association_class}
            @#{association_name} ||= @#{association_name}_class.where(id: #{association_name}_id).first if #{association_name}_id
          end

          def #{association_name}=(object)
            @#{association_name} = object
            self.#{association_name}_id = object.try :id
            #{"self.#{association_name}_type = object.class.name" if options[:polymorphic].present?}
          end
        >
        end
      end
    end
  end
end