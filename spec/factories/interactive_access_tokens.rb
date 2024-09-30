# frozen_string_literal: true
FactoryBot.define do
  factory :interactive_access_token do
    association :session, factory: :published_session
    individual { [true, false].sample }
    token { SecureRandom.hex }
  end

  factory :interactive_access_token_active, parent: :interactive_access_token do
    after(:create) do |token|
      start_at = 10.minutes.ago
      end_at = 10.minutes.from_now
      token.session.update_columns(start_at: start_at)
      token.session.room.update_columns(actual_start_at: start_at, actual_end_at: end_at)
    end
  end

  factory :interactive_access_token_individual, parent: :interactive_access_token_active do
    individual { true }
  end

  factory :interactive_access_token_shared, parent: :interactive_access_token_active do
    individual { false }
  end

  factory :interactive_access_token_shared_with_guests, parent: :interactive_access_token_shared do
    guests { true }
  end

  factory :interactive_access_token_expired, parent: :interactive_access_token do
    individual { false }
    association :session, factory: :recorded_session
  end

  factory :aa_stub_interactive_access_tokens, parent: :interactive_access_token
end
