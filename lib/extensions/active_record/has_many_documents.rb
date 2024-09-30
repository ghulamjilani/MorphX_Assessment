# frozen_string_literal: true

module Extensions
  module ActiveRecord
    module HasManyDocuments
      extend ActiveSupport::Concern

      module ClassMethods
        def has_many_documents(association_name, options = {})
          association_class = options[:class_name] || association_name.to_s.singularize.classify

          if options[:dependent] == :destroy
            class_eval %(
              after_destroy :destroy_#{association_name}

              def destroy_#{association_name}
                #{association_name}.destroy
              end
            )
          end

          where = {}
          where = if options[:as].present?
                    "#{options[:as]}_id: id, #{options[:as]}_type: self.class.name"
                  elsif options[:foreign_key].present? && options[:foreign_type].blank?
                    "#{options[:foreign_key]}: id"
                  else
                    "#{name.underscore}_id: id"
                  end
          class_eval %<
            def #{association_name}
              #{association_class}.where(#{where})
            end
          >
        end
      end
    end
  end
end
