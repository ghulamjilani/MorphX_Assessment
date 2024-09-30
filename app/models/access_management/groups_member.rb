# frozen_string_literal: true
module AccessManagement
  class GroupsMember < AccessManagement::ApplicationRecord
    include ActiveModel::ForbiddenAttributesProtection
    include ModelConcerns::ActiveModel::Extensions
    belongs_to :group, class_name: 'AccessManagement::Group', foreign_key: :access_management_group_id, touch: true
    belongs_to :organization_membership, class_name: 'OrganizationMembership',
                                         foreign_key: :organization_membership_id, touch: true
    has_one :user, through: :organization_membership
    has_many :groups_members_channels, class_name: 'AccessManagement::GroupsMembersChannel',
                                       foreign_key: :access_management_groups_member_id, dependent: :destroy
    has_many :channels, through: :groups_members_channels, source: :channel
    has_many :credentials, -> { active }, through: :group
    validates :organization_membership_id, uniqueness: { scope: :access_management_group_id }
    after_commit { user&.touch if user&.persisted? }
  end
end
