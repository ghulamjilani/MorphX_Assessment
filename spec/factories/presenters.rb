# frozen_string_literal: true
FactoryBot.define do
  factory :presenter do
    user
  end

  factory :presenter_with_presenter_account, parent: :presenter do
    association :user, factory: :user_with_presenter_account
  end

  factory :presenter_fake, parent: :presenter do
    association :user, factory: :user_fake
  end

  factory :aa_stub_presenters, parent: :presenter
end
