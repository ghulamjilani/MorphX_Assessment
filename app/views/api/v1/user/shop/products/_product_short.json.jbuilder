# frozen_string_literal: true

json.cache! product, expires_in: 1.day do
  json.id                product.id
  json.title             product.title
  json.description       product.description
  json.url               product.url
  json.price_cents       product.price_cents
  json.price_currency    product.price_currency
  json.base_url          product.base_url
end
