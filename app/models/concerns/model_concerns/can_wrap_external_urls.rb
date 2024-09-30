# frozen_string_literal: true

module ModelConcerns
  module CanWrapExternalUrls
    extend ActiveSupport::Concern

    included do
      def self.wrap_external_urls(field)
        define_method "#{field}_without_external_urls" do
          Rails.cache.fetch("#{field}_without_external_urls/#{cache_key}") do
            doc = Nokogiri::HTML.fragment(read_attribute(field))
            doc.css('a').each do |a|
              a.set_attribute('rel', 'noindex nofollow')
              a.set_attribute('target', '_blank')
            end
            doc.to_s.html_safe
          end
        end
      end
    end

    module ClassMethods
      def link_wrapper(*attribute_names)
        attribute_names.each do |attr|
          before_validation "wrap_#{attr}_links".to_sym, if: proc { |object| object.send("#{attr}_changed?") }

          define_method "wrap_#{attr}_links".to_sym do
            if self[attr].present?
              self[attr] =
                Html::Parser.new(self[attr]).wrap_urls(html_attributes: { target: '_blank' }).to_s.html_safe
            end
          end
        end
      end
    end
  end
end
