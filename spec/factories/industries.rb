# frozen_string_literal: true
FactoryBot.define do
  factory :industry do
    description { %w[Pharmaceuticals Music Nanotechnology].sample }
  end
  factory :aa_stub_industries, parent: :industry
end
