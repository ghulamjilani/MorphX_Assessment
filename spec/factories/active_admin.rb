# frozen_string_literal: true

FactoryBot.define do
  factory :aa_stub_dashboard, parent: :user do
    after(:create) do
      create(:user)
    end
  end
  factory :aa_stub_mailing, parent: :video
  factory :aa_stub_system_reports, parent: :video
  factory :aa_stub_basic_auth, parent: :video
end
