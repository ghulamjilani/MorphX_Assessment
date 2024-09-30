# frozen_string_literal: true

json.extract! booking, :id, :status, :duration, :start_at, :end_at, :customer_paid, :created_at, :updated_at, :comment
json.user do
  json.partial! 'api/v1/user/users/user_short', user: booking.user
  json.phone booking.user.user_account&.cellphone
end
json.session do
  json.id booking.session_id
  json.url booking.session&.absolute_path
  json.title booking.session&.title
  json.replay !booking.session&.recorded_purchase_price.nil?
  json.price_cents booking.payment_transaction&.amount || booking.booking_price&.price_cents
end
