# frozen_string_literal: true
FactoryBot.define do
  factory :signup_token do
    user { nil }
  end

  factory :aa_stub_signup_tokens, parent: :signup_token
end
