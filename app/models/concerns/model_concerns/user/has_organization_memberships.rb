# frozen_string_literal: true

module ModelConcerns
  module User
    module HasOrganizationMemberships
      extend ActiveSupport::Concern

      included do
        has_many :organization_memberships, dependent: :destroy
        has_many :organization_memberships_participants, -> { where(membership_type: :participant) }, class_name: 'OrganizationMembership', inverse_of: :user
        has_many :organization_memberships_guests, -> { where(membership_type: :guest) }, class_name: 'OrganizationMembership', inverse_of: :user
        has_many :organization_memberships_active, lambda {
                                                     participants.where(status: OrganizationMembership::Statuses::ACTIVE)
                                                   }, class_name: 'OrganizationMembership', inverse_of: :user
        has_many :organizations, through: :organization_memberships_active, source: :organization
        has_many :groups, through: :organization_memberships_active
        has_many :groups_members, through: :organization_memberships_active
        has_many :groups_members_channels, through: :groups_members
        has_many :credentials, -> { active }, class_name: 'AccessManagement::Credential', through: :organization_memberships_active, source: :credentials
      end

      # Defines if current user has active membership of specified type in current organization(current_organization_participant? ; current_organization_guest?)
      OrganizationMembership.membership_types.each_key do |membership_type|
        define_method("current_organization_#{membership_type}?") do
          return false unless current_organization
          return true if membership_type.eql?('participant') && current_organization.user_id == id

          Rails.cache.fetch("user/#{__method__}/#{id}/#{cache_key}") do
            current_organization.organization_memberships.exists?(status: ::OrganizationMembership::Statuses::ACTIVE, user_id: id, membership_type: membership_type)
          end
        end
      end

      def current_organization_membership
        organization_memberships.find_by(organization: current_organization)
      end

      def current_organization_membership_type
        Rails.cache.fetch("user/#{__method__}/#{id}/#{cache_key}") do
          lambda do
            return 'owner' if current_organization&.user_id == id

            current_organization_membership&.membership_type
          end.call
        end
      end
    end
  end
end
