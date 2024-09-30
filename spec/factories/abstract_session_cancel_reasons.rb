# frozen_string_literal: true
FactoryBot.define do
  factory :abstract_session_cancel_reason do
    sequence(:name) { |n| "synthetic-cancel-reason-#{n}" }
  end
  factory :aa_stub_abstract_session_cancel_reasons, parent: :abstract_session_cancel_reason
end
