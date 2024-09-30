# frozen_string_literal: true

FactoryBot.define do
  factory :pg_search_document do
    association :user
    association :channel
  end

  factory :aa_stub_pg_search_documents, parent: :pg_search_document
end
