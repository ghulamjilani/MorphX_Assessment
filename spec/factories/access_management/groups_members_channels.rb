# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_groups_members_channel, class: 'AccessManagement::GroupsMembersChannel' do
    association :groups_member, factory: :access_management_groups_member
    channel { create(:listed_channel, organization: groups_member.organization_membership.organization) }
  end
  factory :aa_stub_access_management_groups_members_channels, parent: :access_management_groups_members_channel
end
