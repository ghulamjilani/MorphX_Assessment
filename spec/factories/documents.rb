# frozen_string_literal: true
FactoryBot.define do
  factory :document do
    association :channel, factory: :approved_channel
    description { Forgery(:lorem_ipsum).words(8) }
    hidden { false }
    after(:build) do |document|
      document.file.attach(io: File.open(Rails.root.join('spec', 'fixtures', 'active_storage', 'test.pdf')), filename: 'test.pdf', content_type: 'application/pdf')
    end
  end

  factory :document_with_own_title, parent: :document do
    title { Forgery(:lorem_ipsum).words(3) }
  end

  factory :aa_stub_documents, parent: :document
end
