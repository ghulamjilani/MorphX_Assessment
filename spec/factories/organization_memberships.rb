# frozen_string_literal: true
FactoryBot.define do
  factory :organization_membership do
    user { create(:presenter).user }
    organization
    role { OrganizationMembership::Roles::ALL.sample }
    status { OrganizationMembership::Statuses::ACTIVE }
    membership_type { :participant } # default membership_type
  end

  factory :organization_membership_pending, parent: :organization_membership do
    status { OrganizationMembership::Statuses::PENDING } # default status
  end

  factory :organization_membership_active, parent: :organization_membership do
    status { OrganizationMembership::Statuses::ACTIVE }
  end

  factory :organization_membership_cancelled, parent: :organization_membership do
    status { OrganizationMembership::Statuses::CANCELLED }
  end

  factory :organization_membership_suspended, parent: :organization_membership do
    status { OrganizationMembership::Statuses::SUSPENDED }
  end

  factory :organization_membership_administrator, parent: :organization_membership do
    after(:create) do |member|
      gm = create(:access_management_groups_member, organization_membership: member)
      credential = create(:access_management_credential, code: :manage_organization)
      create(:access_management_groups_credential, credential: credential, group: gm.group)
    end
  end

  factory :organization_membership_blog_moderator, parent: :organization_membership do
    after(:create) do |member|
      gm = create(:access_management_groups_member, organization_membership: member)
      credential = create(:access_management_credential, code: :moderate_blog_post)
      create(:access_management_groups_credential, credential: credential, group: gm.group)
    end
  end

  factory :organization_membership_blog_manager, parent: :organization_membership do
    after(:create) do |member|
      gm = create(:access_management_groups_member, organization_membership: member)
      credential = create(:access_management_credential, code: :manage_blog_post)
      create(:access_management_groups_credential, credential: credential, group: gm.group)
    end
  end

  factory :organization_membership_guest, parent: :organization_membership do
    membership_type { :guest }
  end

  factory :aa_stub_organization_memberships, parent: :organization_membership
end
