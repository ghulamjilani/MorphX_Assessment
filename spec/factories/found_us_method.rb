# frozen_string_literal: true

FactoryBot.define do
  factory :found_us_method do
    sequence(:description) { |n| "Found us Method ##{n}" }
  end
  factory :aa_stub_found_us_methods, parent: :found_us_method
end
