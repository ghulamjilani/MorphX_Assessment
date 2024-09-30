# frozen_string_literal: true

envelope json do
  json.array! @merchant_categories do |merchant_category|
    json.partial! 'api/v1/user/payouts/merchant_categories/merchant_category', merchant_category: merchant_category
  end
end
