# frozen_string_literal: true
FactoryBot.define do
  factory :wishlist_item do
    association :model, factory: :immersive_session
    association :user, factory: :user
  end
  factory :aa_stub_wishlist_items, parent: :wishlist_item
end
