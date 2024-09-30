# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_group, class: 'AccessManagement::Group' do
    code { :super_admin }
    description { Forgery(:lorem_ipsum).paragraphs(1) }
    name { Forgery(:lorem_ipsum).title(random: true) }
    system { true }
  end

  factory :access_management_organizational_group, parent: :access_management_group do
    code { nil }
    system { false }
    association :organization
  end

  factory :aa_stub_access_management_groups, parent: :access_management_group
end
