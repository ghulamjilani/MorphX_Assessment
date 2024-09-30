# frozen_string_literal: true
class AccessManagement::Group < AccessManagement::ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id, if: :organization_id }
  validates :name, exclusion: { in: lambda { |_group|
                                      AccessManagement::Group.where(system: true).pluck(:name)
                                    }, if: :organization_id }
  validates :organization_id, presence: { unless: :system? }
  belongs_to :organization
  has_many :groups_credentials, class_name: 'AccessManagement::GroupsCredential', inverse_of: :group,
                                foreign_key: :access_management_group_id, dependent: :destroy
  has_many :groups_members, class_name: 'AccessManagement::GroupsMember', inverse_of: :group,
                            foreign_key: :access_management_group_id, dependent: :destroy
  has_many :credentials, -> { active }, class_name: 'AccessManagement::Credential', through: :groups_credentials, source: :credential
  has_many :users, through: :groups_members, source: :user
  after_commit { users.update_all(updated_at: Time.now.utc) }

  accepts_nested_attributes_for :credentials

  scope :for_organization, lambda { |organization_id|
                             where(enabled: true).where('access_management_groups.system = TRUE OR access_management_groups.organization_id = ?', organization_id)
                           }

  def is_for_channel?
    credentials.exists?(is_for_channel: true)
  end
end
