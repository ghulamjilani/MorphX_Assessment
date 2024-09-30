# frozen_string_literal: true

FactoryBot.define do
  factory :visitor_source do
    visitor_id { SecureRandom.alphanumeric(8).downcase }
  end
  factory :aa_stub_affiliate_tracking, parent: :visitor_source
end
