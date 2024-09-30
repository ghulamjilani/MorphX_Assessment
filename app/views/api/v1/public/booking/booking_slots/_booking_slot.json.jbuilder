# frozen_string_literal: true

json.extract! booking_slot, :id, :name, :description, :replay, :replay_price_cents, :currency,
              :tags, :slot_rules, :week_rules, :booking_category_id, :channel_id, :created_at, :updated_at
json.booking_prices do
  json.array! booking_slot.booking_prices do |price|
    json.extract! price, :id, :price_cents, :currency, :duration
  end
end
json.user do
  json.partial! 'api/v1/user/users/user_short', user: booking_slot.user
end
json.channel do
  json.id booking_slot.channel_id
  json.title booking_slot.channel&.title
end
json.category do
  json.id booking_slot.booking_category_id
  json.name booking_slot.booking_category&.name
end
