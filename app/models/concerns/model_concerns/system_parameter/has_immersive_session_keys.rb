# frozen_string_literal: true

module ModelConcerns::SystemParameter::HasImmersiveSessionKeys
  extend ActiveSupport::Concern

  included do
    %w[group one_on_one].each do |type|
      freezed_const_set("MAX_#{type.upcase}_IMMERSIVE_SESSION_ACCESS_COST")
      # @return [BigDecimal]
      define_singleton_method "max_#{type}_immersive_session_access_cost" do
        fetch_value(const_get("MAX_#{type.upcase}_IMMERSIVE_SESSION_ACCESS_COST"))
      end
    end
    %w[free_private_interactive_count].each do |type|
      freezed_const_set(type.upcase)
      # @return [Integer]
      define_singleton_method type do
        fetch_value(const_get(type.upcase))
      end
    end
  end
end
