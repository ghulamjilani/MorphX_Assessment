# frozen_string_literal: true

module ModelConcerns::User::HasCredentials
  extend ActiveSupport::Concern

  # Returns true if organization owner or has any credential by code
  def has_any_credential?(code)
    return false unless persisted?

    Rails.cache.fetch("user/has_any_credential/#{cache_key}/#{code}") do
      lambda do
        return false unless ::AccessManagement::Credential.active.exists?(code: code)
        return true if organization.present? && organization.id == current_organization_id

        credentials.exists?(code: code)
      end.call
    end
  end

  # Returns true if organization owner or has any role with corresponding credential regardless attached channels
  def has_any_organization_credential?(organization, credential_code)
    return false unless persisted?

    Rails.cache.fetch("user/any_organization_credential/#{organization.cache_key}/#{cache_key}/#{credential_code}") do
      lambda do
        return false unless ::AccessManagement::Credential.active.exists?(code: credential_code)
        return true if organization.user == self

        credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: credential_code)
      end.call
    end
  end

  # Returns true if organization owner or has role with corresponding credential that is not attached to any channel
  def has_organization_credential?(organization, credential_code)
    return false unless persisted?

    Rails.cache.fetch("user/has_organization_credential/#{organization.cache_key}/#{cache_key}/#{credential_code}") do
      lambda do
        return false unless ::AccessManagement::Credential.active.exists?(code: credential_code)
        return true if organization.user == self
        return false unless (organization_membership = active_organization_membership(organization))

        groups_members = organization_membership.groups_members.joins(group: :credentials)
                                                .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
                                                .where(access_management_credentials: { is_enabled: true, code: credential_code })
                                                .joins('LEFT JOIN access_management_groups_members_channels on access_management_groups_members.id = access_management_groups_members_channels.access_management_groups_member_id')
                                                .exists?(access_management_groups_members_channels: { channel_id: nil })
      end.call
    end
  end

  # Returns true if channel organization owner or has role with corresponding credential that is not attached to any channel or attached to the required channel
  def has_channel_credential?(channel, credential_code)
    return false unless persisted?

    Rails.cache.fetch("user/has_channel_credential/#{channel.cache_key}/#{cache_key}/#{credential_code}") do
      lambda do
        return false unless ::AccessManagement::Credential.active.exists?(code: credential_code)

        organization = channel.organization
        return true if organization.user == self
        return false unless (organization_membership = active_organization_membership(organization))

        groups_members = organization_membership.groups_members.joins(group: :credentials)
                                                .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
                                                .where(access_management_credentials: { is_enabled: true, code: credential_code })
                                                .joins('LEFT JOIN access_management_groups_members_channels on access_management_groups_members.id = access_management_groups_members_channels.access_management_groups_member_id')
                                                .exists?([
                                                           'access_management_groups_members_channels.channel_id IS NULL OR access_management_groups_members_channels.channel_id = :channel_id', { channel_id: channel.id }
                                                         ])
      end.call
    end
  end

  # Returns Channel ActiveRecord Relation with channels that are available for user's group member for specified organization and credential codes
  def organization_channels_with_credentials(organization, credential_code)
    return Channel.none unless organization && credential_code.present? && persisted?
    return organization.channels if has_organization_credential?(organization, credential_code)
    return Channel.none unless (organization_membership = active_organization_membership(organization))

    channel_ids = Rails.cache.fetch("user/organization_channels_with_credentials/channels_with_credentials/#{cache_key}/#{organization.cache_key}/#{credential_code}") do
      lambda do
        AccessManagement::GroupsMembersChannel
          .joins(groups_member: { group: :credentials })
          .where(access_management_groups_members: { organization_membership_id: organization_membership.id }, access_management_credentials: { is_enabled: true, code: credential_code })
          .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
          .pluck(:channel_id)
      end.call
    end
    Channel.where(id: channel_ids)
  end

  # Returns Channel ActiveRecord Relation with channels that are available for user for specified credential codes from all organizations with active membership
  def all_channels_with_credentials(credential_code)
    return Channel.none unless credential_code.present? && persisted?

    active_memberships_ids = organization_memberships_active.pluck(:id)
    channels_ids = owned_channels.pluck(:id)
    channels_ids += AccessManagement::GroupsMembersChannel
                    .joins(group: :credentials)
                    .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
                    .where(access_management_groups_members: { organization_membership_id: active_memberships_ids }, access_management_credentials: { is_enabled: true, code: credential_code })
                    .pluck(:channel_id)

    groups_with_credentials = AccessManagement::GroupsMember
                              .joins(group: :credentials)
                              .joins('LEFT JOIN access_management_groups_members_channels ON access_management_groups_members.id = access_management_groups_members_channels.access_management_groups_member_id')
                              .where(access_management_groups_members_channels: { channel_id: nil })
                              .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
                              .where(
                                access_management_groups_members: { organization_membership_id: active_memberships_ids },
                                access_management_credentials: { is_enabled: true, code: credential_code }
                              )

    custom_groups_ids = groups_with_credentials.where.not(access_management_groups: { organization_id: nil })
                                               .pluck(:access_management_group_id)
    organizations_ids_with_credentials = AccessManagement::Group.where(id: custom_groups_ids).pluck(:organization_id).uniq
    organizations_ids_with_credentials += Organization.where(user: self).pluck(:id)
    om_ids_with_system_groups = groups_with_credentials.where(access_management_groups: { organization_id: nil })
                                                       .pluck(:organization_membership_id)
    organizations_ids_with_credentials += OrganizationMembership.where(id: om_ids_with_system_groups).pluck(:organization_id)
    channels_ids += Channel.where(organization_id: organizations_ids_with_credentials).pluck(:id)
    if Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
      Channel.joins('JOIN organizations ON organizations.id = channels.organization_id')
             .joins('JOIN users ON users.id = organizations.user_id')
             .joins('LEFT JOIN stripe_service_subscriptions ON stripe_service_subscriptions.user_id = users.id')
             .where("stripe_service_subscriptions.service_status != 'deactivated' OR organizations.split_revenue_plan = TRUE")
             .where(id: channels_ids)
    else
      Channel.where(id: channels_ids)
    end
  end
end
