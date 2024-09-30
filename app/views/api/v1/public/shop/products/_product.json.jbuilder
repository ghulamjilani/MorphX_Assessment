# frozen_string_literal: true

json.cache! product, expires_in: 1.day do
  json.id                product.id
  json.title             product.title
  json.description       product.description
  json.short_description product.short_description
  json.url               product.url
  json.image_url         product.image_url
  json.specifications    product.specifications
  json.price_cents       product.price_cents
  json.price_currency    product.price_currency
  json.base_url          product.base_url
  json.affiliate_url     product.affiliate_url
  json.partner           product.partner
  json.barcodes          product.barcodes
  json.raw_info          product.raw_info
end