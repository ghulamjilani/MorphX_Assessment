# frozen_string_literal: true

envelope json, (@status || 200) do
  json.coupon do
    json.code @coupon.stripe_id
    json.name @coupon.name
    json.amount_off @coupon.amount_off
    json.currency @coupon.stripe_object.currency
    json.percent_off @coupon.percent_off_precise
    json.duration @coupon.duration
    json.duration_in_months @coupon.duration_in_months
  end
  json.savings @savings
  json.total @total
end
