# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_credential, class: 'AccessManagement::Credential' do
    name { Forgery(:lorem_ipsum).title(random: true) }
    code { AccessManagement::Credential::Codes::ALL.sample }
    is_enabled { true }
    is_master_only { false }
    association :category, factory: :access_management_category
    association :type, factory: :access_management_type
  end

  factory :admin_credential, parent: :access_management_credential do
    association :type, factory: :admin_access_management_type
  end

  factory :creator_credential, parent: :access_management_credential do
    association :type, factory: :creator_access_management_type
  end

  factory :manage_admin_credential, parent: :access_management_credential do
    code { AccessManagement::Credential::Codes::MANAGE_ADMIN }
  end

  factory :aa_stub_access_management_credentials, parent: :access_management_credential
end
