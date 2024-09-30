# frozen_string_literal: true
FactoryBot.define do
  factory :studio do
    organization
    sequence(:name) { |n| "#{organization.name} Studio ##{n} - #{Forgery('name').company_name}" }
    description { "description-#{Forgery(:lorem_ipsum).words(22)}" }
    phone { Forgery(:address).phone }
    address do
      "#{Forgery(:address).street_address}, #{Forgery(:address).city} #{Forgery(:address).state_abbrev} #{Forgery(:address).zip}, USA"
    end
  end

  factory :aa_stub_studios, parent: :studio
end
