# frozen_string_literal: true
FactoryBot.define do
  factory :rate do
    association :rater, factory: :user
    stars { [1, 2, 3, 4, 5].sample }
    dimension { Session::RateKeys::QUALITY_OF_CONTENT }
    association :rateable, factory: :immersive_session
  end

  factory :aa_stub_rates, parent: :rate
end
