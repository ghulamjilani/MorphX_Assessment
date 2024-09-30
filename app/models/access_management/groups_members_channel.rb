# frozen_string_literal: true
class AccessManagement::GroupsMembersChannel < AccessManagement::ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  belongs_to :channel, class_name: 'Channel'
  belongs_to :groups_member, class_name: 'AccessManagement::GroupsMember',
                             foreign_key: :access_management_groups_member_id, touch: true
  has_one :group, through: :groups_member, source: :group
  has_many :credentials, -> { active }, through: :group, source: :credentials
  has_one :organization_membership, through: :groups_member
  has_one :user, through: :organization_membership, source: :user
  after_commit -> { groups_member&.touch }, on: :create
  after_destroy { groups_member&.touch }
end
