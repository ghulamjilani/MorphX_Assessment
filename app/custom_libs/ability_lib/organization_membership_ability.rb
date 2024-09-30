# frozen_string_literal: true

module AbilityLib
  class OrganizationMembershipAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        read: [OrganizationMembership]
      }
    end

    def load_permissions
      can :read, OrganizationMembership do |organization_membership|
        lambda do
          return true if organization_membership.active?
          return false unless user.persisted?
          return true if organization_membership.user == user

          user.has_organization_credential?(organization_membership.organization,
                                            %i[manage_admin manage_creator manage_enterprise_member])
        end.call
      end

      can :edit_roles, OrganizationMembership do |organization_membership|
        Rails.cache.fetch("organization_membership_ability/edit_roles/organization_membership/#{organization_membership.organization.cache_key}/#{user.cache_key}") do
          lambda do
            return false if user.new_record? || user == organization_membership.user

            user.has_organization_credential?(organization_membership.organization, :manage_roles)
          end.call
        end
      end
    end
  end
end
