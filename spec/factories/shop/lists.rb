# frozen_string_literal: true
FactoryBot.define do
  factory :list, class: 'Shop::List' do
    sequence(:name) { |n| "Test List ##{n}" }
    description { name * 5 }
    sequence(:url) { |n| "list-#{n}.com" }
    organization
  end
  factory :aa_stub_lists, parent: :list
end
