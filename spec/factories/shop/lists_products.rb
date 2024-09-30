# frozen_string_literal: true
FactoryBot.define do
  factory :lists_product, class: 'Shop::ListsProduct' do
    list
    product
  end
  factory :aa_stub_lists_products, parent: :lists_product
end
