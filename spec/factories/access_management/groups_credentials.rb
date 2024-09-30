# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_groups_credential, class: 'AccessManagement::GroupsCredential' do
    association :group, factory: :access_management_group
    association :credential, factory: :access_management_credential
  end

  factory :access_management_organizational_groups_credential, parent: :access_management_groups_credential do
    association :group, factory: :access_management_organizational_group
  end

  factory :access_management_organizational_groups_manage_admin_credential, parent: :access_management_organizational_groups_credential do
    association :credential, factory: :manage_admin_credential
  end

  factory :aa_stub_access_management_groups_credentials, parent: :access_management_groups_credential
end
