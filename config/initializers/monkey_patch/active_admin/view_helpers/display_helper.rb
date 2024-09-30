# frozen_string_literal: true

module ActiveAdmin
  module ViewHelpers
    module DisplayHelper
      def pretty_format(object)
        case object
        when String, Numeric, Symbol, Arbre::Element
          object.to_s
        when Date, Time
          if defined?(utc_and_admin_time_formatted)
            utc_and_admin_time_formatted(object, MORPHX_TIME_FORMAT)
          else
            I18n.l(object, format: active_admin_application.localize_format)
          end
        when Array
          format_collection(object)
        else
          if (defined?(::ActiveRecord) && object.is_a?(ActiveRecord::Base)) ||
             (defined?(::Mongoid) && object.class.include?(Mongoid::Document))
            auto_link object
          elsif defined?(::ActiveRecord) && object.is_a?(ActiveRecord::Relation)
            format_collection(object)
          else
            display_name object
          end
        end
      end
    end
  end
end
