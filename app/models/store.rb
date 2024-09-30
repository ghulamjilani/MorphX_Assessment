# frozen_string_literal: true
class Store < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  monetize :min_price_cents, with_model_currency: :price_currency
  monetize :max_price_cents, with_model_currency: :price_currency

  belongs_to :product

  def formatted_url
    format_url
    url
  end

  private

  def format_url
    self.url = "https://#{url}" unless url.start_with?('http')
  end
end
