# frozen_string_literal: true

FactoryBot.define do
  factory :ban_reason do
    sequence(:name) { |n| "synthetic-ban-reason-#{n}" }
  end

  factory :aa_stub_ban_reasons, parent: :ban_reason
end
