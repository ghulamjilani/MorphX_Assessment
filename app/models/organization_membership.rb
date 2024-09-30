# frozen_string_literal: true
class OrganizationMembership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  # TODO: setup correct roles
  module Roles
    CONTENT_MANAGER = 'manager'
    ADMINISTRATOR = 'administrator'
    PRESENTER = 'presenter'

    ALL = [CONTENT_MANAGER, ADMINISTRATOR, PRESENTER].freeze
    OPTIONS_FOR_SELECT = [['Manager', CONTENT_MANAGER],
                          ['Administrator', ADMINISTRATOR],
                          ['Presenter', PRESENTER]].freeze
  end

  module Statuses
    PENDING = 'pending'
    ACTIVE = 'active'
    CANCELLED = 'cancelled'
    SUSPENDED = 'suspended'

    ALL = [PENDING, ACTIVE, CANCELLED, SUSPENDED].freeze
  end

  enum membership_type: {
    participant: 0,
    guest: 1
  }

  belongs_to :organization, touch: true
  belongs_to :user, touch: true
  has_one :presenter, through: :user

  has_many :groups_members, class_name: 'AccessManagement::GroupsMember', dependent: :destroy
  has_many :groups, through: :groups_members, source: :group
  has_many :groups_members_channels, through: :groups_members, source: :groups_members_channels
  has_many :channels, through: :groups_members_channels, source: :channel
  has_many :groups_credentials, through: :groups
  has_many :credentials, -> { active }, class_name: 'AccessManagement::Credential', through: :groups_credentials

  validates :user_id, :organization_id, presence: true
  validates :status, presence: true, inclusion: { in: ::OrganizationMembership::Statuses::ALL }
  validates :user, uniqueness: { scope: [:organization], if: :organization }
  validate :not_owner_validation

  before_validation :set_default_role, on: :create

  after_destroy :notify_user_about_rejecting, if: :organization
  after_commit :notify_user_about_adding, if: ->(om) { om.pending? && (om.instance_variable_get(:@_new_record_before_last_commit) || om.saved_change_to_status?) }, on: %i[create update]
  after_commit :notify_user_about_rejecting, if: ->(om) { om.saved_change_to_status? && (om.cancelled? || om.suspended?) }, on: %i[update]

  after_commit :set_user_organization, if: ->(om) { om.saved_change_to_status? }, on: %i[create update]

  scope :admins, -> { joins(credentials: :type).where(access_management_types: { name: 'Admin' }).group(:id) }
  scope :creators, -> { joins(credentials: :type).where(access_management_types: { name: 'Creator' }).group(:id) }
  scope :members, -> { joins(credentials: :type).where(access_management_types: { name: 'Member' }).group(:id) }

  scope :active, -> { where(status: OrganizationMembership::Statuses::ACTIVE) }
  scope :pending, -> { where(status: OrganizationMembership::Statuses::PENDING) }
  scope :cancelled, -> { where(status: OrganizationMembership::Statuses::CANCELLED) }
  scope :suspended, -> { where(status: OrganizationMembership::Statuses::SUSPENDED) }
  scope :active_or_pending, -> { where(status: [OrganizationMembership::Statuses::ACTIVE, OrganizationMembership::Statuses::PENDING]) }

  scope :participants, -> { where(membership_type: :participant) }
  scope :guests, -> { where(membership_type: :guest) }

  OrganizationMembership::Statuses::ALL.each do |const|
    define_method("#{const}?") { status == const }
    define_method("#{const}!") { update(status: const) }
  end

  def self.for_channel_by_credential(channel_id, credential_code, limit = nil, offset = 0)
    channel = Channel.find(channel_id)
    OrganizationMembership.find_by_sql(
      [%{SELECT organization_memberships.*
            FROM organization_memberships
            WHERE organization_memberships.id IN (
              SELECT organization_memberships.id FROM organization_memberships
                INNER JOIN access_management_groups_members ON access_management_groups_members.organization_membership_id = organization_memberships.id
                INNER JOIN access_management_groups ON access_management_groups.id = access_management_groups_members.access_management_group_id
                INNER JOIN access_management_groups_credentials ON access_management_groups_credentials.access_management_group_id = access_management_groups.id
                INNER JOIN access_management_credentials ON access_management_credentials.id = access_management_groups_credentials.access_management_credential_id
                INNER JOIN access_management_groups_members_channels ON access_management_groups_members_channels.access_management_groups_member_id = access_management_groups_members.id
                WHERE access_management_credentials.code IN (:credential_code) AND access_management_groups_members_channels.channel_id = :channel_id AND organization_memberships.organization_id = :organization_id
              UNION
              SELECT organization_memberships.id FROM organization_memberships
                INNER JOIN access_management_groups_members ON access_management_groups_members.organization_membership_id = organization_memberships.id
                INNER JOIN access_management_groups ON access_management_groups.id = access_management_groups_members.access_management_group_id
                INNER JOIN access_management_groups_credentials ON access_management_groups_credentials.access_management_group_id = access_management_groups.id
                INNER JOIN access_management_credentials ON access_management_credentials.id = access_management_groups_credentials.access_management_credential_id
                LEFT JOIN access_management_groups_members_channels ON access_management_groups_members_channels.access_management_groups_member_id = access_management_groups_members.id
                WHERE access_management_credentials.code IN (:credential_code) AND organization_memberships.organization_id = :organization_id GROUP BY organization_memberships.id HAVING COUNT(access_management_groups_members_channels.*) = 0
      ) AND organization_memberships.status = :status ORDER BY organization_memberships.id ASC LIMIT :limit OFFSET :offset},
       { credential_code: credential_code, channel_id: channel_id, organization_id: channel.organization.id, status: OrganizationMembership::Statuses::ACTIVE, limit: limit, offset: offset }]
    )
  end

  def email
    user.try(:email)
  end

  def to_form_json
    {
      id: id,
      user_id: user_id,
      role: role,
      position: position,
      private: private,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      name: user.public_display_name || user.email
    }
  end

  private

  # Notify all except company owner
  def notify_user_about_adding
    CompanyMailer.employee_invited(id).deliver_later if user_id != organization.user_id
  end

  def notify_user_about_rejecting
    return if guest? || user_id == organization.user_id

    CompanyMailer.employee_rejected(user_id, organization_id).deliver_later
  end

  # TODO: remove
  def set_default_role
    self.role = Roles::PRESENTER if role.blank?
  end

  def not_owner_validation
    errors.add(:user, 'organization owner cannot be invited to organization') if user == organization.user
  end

  def set_user_organization
    case status
    when OrganizationMembership::Statuses::ACTIVE
      unless user.current_organization_id?
        user.current_organization_id = organization_id
        user.save(validate: false)
      end
    else
      if organization_id == user.current_organization_id
        available_organization_id = user.organization_memberships.active.order(membership_type: :asc).pick(:organization_id)
        user.current_organization_id = available_organization_id
        user.save(validate: false)
      end
    end
  end
end
