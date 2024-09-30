# frozen_string_literal: true

module AccessManagement
  module CredentialsHelper
    class << self
      def group_member_with_channel_credential(user:, code:, channel:)
        group_member = group_member_with_credential(organization: channel.organization, user:, code:)
        group_member.groups_members_channels.create(channel: channel)
        group_member
      end

      def group_member_with_credential(user:, code:, organization:)
        om = organization_membership(user:, organization:)
        group = group_with_credential(code:, organization:)
        AccessManagement::GroupsMember.create!(organization_membership: om, group:)
      end

      def group_with_credential(code:, organization:)
        group = FactoryBot.create(:access_management_organizational_group, organization:)
        credential = AccessManagement::Credential.find_by(code: code) || FactoryBot.create(:access_management_credential, code:)
        AccessManagement::GroupsCredential.create!(group:, credential:)
        group
      end

      def organization_membership(user:, organization:)
        user.organization_memberships_participants.active.find_by(organization_id: organization.id) ||
          FactoryBot.create(:organization_membership_active, user:, organization:)
      end
    end
  end
end
