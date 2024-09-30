# frozen_string_literal: true

module AbilityLib
  module AccessManagement
    class GroupAbility < AbilityLib::AccessManagement::Base
      def service_admin_abilities
        @service_admin_abilities ||= {}
      end

      def load_permissions
        can :add_credential, [::AccessManagement::Group, ::AccessManagement::Credential] do |group, credential|
          organization = group.organization

          Rails.cache.fetch("access_management/group_ability/add_credential/group/#{group.cache_key}/organization/#{organization.cache_key}/#{credential.cache_key}") do
            lambda do
              return false unless organization
              return false unless user == organization.user || user.has_organization_credential?(organization, :manage_roles)
              return true unless Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
              return true if organization.split_revenue_plan
              return true if group.credentials.by_type('Admin').present? && credential.type.name == 'Admin'
              return true if group.credentials.by_type('Creator').present? && credential.type.name == 'Creator'

              subscription = organization.user.service_subscription
              return false unless subscription

              # Validate admins count
              if group.credentials.by_type('Admin').blank? && group.groups_members.present? && credential.type.name == 'Admin'
                max_admins_count = subscription&.plan_package ? subscription.plan_package.max_admins_count : 0
                can_invite_admins = max_admins_count == -1 || organization.organization_memberships_participants.admins.active_or_pending.count.size < max_admins_count
                return false unless can_invite_admins
              end

              # Validate creators count
              if group.credentials.by_type('Creator').blank? && group.groups_members.present? && credential.type.name == 'Creator'
                max_creators_count = subscription&.plan_package ? subscription.plan_package.max_creators_count : 0
                can_invite_creators = max_creators_count == -1 || organization.organization_memberships_participants.creators.active_or_pending.count.size < max_creators_count
                return false unless can_invite_creators
              end

              true
            end.call
          end
        end

        can :add_role, [::AccessManagement::Group, OrganizationMembership] do |group, member|
          organization = member.organization
          Rails.cache.fetch("access_management/group_ability/add_role/group/#{group.cache_key}/organization/#{organization.cache_key}/#{user.id}/#{member.cache_key}") do
            lambda do
              if Rails.application.credentials.global.dig(:service_subscriptions, :enabled) && !organization.split_revenue_plan
                # check subscription status
                subscription = organization.user.service_subscription
                return false unless subscription
                return false unless %w[active trial trial_suspended grace pending_deactivation].include?(subscription.service_status)

                # check if limit of admins allows to invite one more
                if group.credentials.joins(:type).exists?(access_management_types: { name: 'Admin' })
                  max_admins_count = subscription&.plan_package ? subscription.plan_package.max_admins_count : 0
                  can_invite_admins = max_admins_count == -1 || organization.organization_memberships_participants.admins.active_or_pending.where.not(organization_memberships: { id: member.id }).count.size < max_admins_count
                  return false unless can_invite_admins
                end
                # check if limit of creators allows to invite one more
                if group.credentials.joins(:type).exists?(access_management_types: { name: 'Creator' })
                  max_creators_count = subscription&.plan_package ? subscription.plan_package.max_creators_count : 0
                  can_invite_creators = max_creators_count == -1 || organization.organization_memberships_participants.creators.active_or_pending.where.not(organization_memberships: { id: member.id }).count.size < max_creators_count
                  return false unless can_invite_creators
                end
              end

              return true if organization.user == user
              # only for owner
              return false if group.credentials.exists?(code: :manage_superadmin)
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Admin' }) && !user.has_organization_credential?(
                organization, :manage_admin
              )
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Creator' }) && !user.has_organization_credential?(
                organization, :manage_creator
              )
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Member' }) && !user.has_organization_credential?(
                organization, :manage_enterprise_member
              )

              true
            end.call
          end
        end
      end
    end
  end
end
