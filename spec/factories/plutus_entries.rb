# frozen_string_literal: true

FactoryBot.define do
  factory :plutus_entry, class: 'Plutus::Entry' do
    description { 'bla bla' }
    association :commercial_document, factory: :video
    after(:build) do |entry|
      entry.credit_amounts << build(:plutus_credit_amount, entry: entry)
      entry.debit_amounts << build(:plutus_debit_amount, entry: entry)
    end
  end

  factory :aa_stub_plutus_entries, parent: :plutus_entry
end
