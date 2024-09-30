# frozen_string_literal: true
FactoryBot.define do
  factory :document_member do
    association :document, factory: :document
    association :user, factory: :user
  end

  factory :aa_stub_document_members, parent: :document_member
end
