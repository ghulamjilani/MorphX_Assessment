# frozen_string_literal: true

module ModelConcerns::SystemParameter::HasNonImmersiveDeliveryMethodKeys
  extend ActiveSupport::Concern

  included do
    %w[livestream recorded].each do |type|
      freezed_const_set("MAX_#{type.upcase}_SESSION_ACCESS_COST")
      # @return [BigDecimal]
      define_singleton_method "max_#{type}_session_access_cost" do
        fetch_value(const_get("MAX_#{type.upcase}_SESSION_ACCESS_COST"))
      end
    end
  end
end
