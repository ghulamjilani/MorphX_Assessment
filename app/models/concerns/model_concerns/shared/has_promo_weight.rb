# frozen_string_literal: true

module ModelConcerns::Shared::HasPromoWeight
  extend ActiveSupport::Concern

  included do
    def current_promo_weight
      return 0 if promo_start.present? && Time.now.utc < promo_start

      return 0 if promo_end.present? && Time.now.utc > promo_end

      promo_weight.to_i
    end
  end
end
