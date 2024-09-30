# frozen_string_literal: true
FactoryBot.define do
  factory :participant do
    user
  end

  factory :participant_with_participant_account, parent: :participant do
    association :user, factory: :user_with_participant_account
  end

  factory :aa_stub_participants, parent: :participant_with_participant_account
end
