# frozen_string_literal: true
FactoryBot.define do
  factory :product, class: 'Shop::Product' do
    sequence(:title) { |n| "Product ##{n}" }
    description { title * 10 }
    sequence(:url) { |n| "http://www.example.com/products/#{n}" }
    short_description { title * 5 }
    specifications { 'Size: 4, 4.5, 5, 5.5' }
    price_cents { Random.rand(3...42) * 100 }
    barcodes { "UPC #{SecureRandom.numeric(12)}, EAN #{SecureRandom.numeric(13)}" }
    organization
  end

  factory :aa_stub_products, parent: :product
end
