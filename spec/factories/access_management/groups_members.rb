# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_groups_member, class: 'AccessManagement::GroupsMember' do
    association :group, factory: :access_management_group
    association :organization_membership
  end

  factory :access_management_organization_groups_member, parent: :access_management_groups_member do
    association :group, factory: :access_management_organizational_group
    organization_membership { create(:organization_membership, organization: group.organization) }
  end

  factory :aa_stub_access_management_groups_members, parent: :access_management_groups_member
end
