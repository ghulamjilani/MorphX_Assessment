# frozen_string_literal: true
class AccessManagement::GroupsCredential < AccessManagement::ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  belongs_to :group, class_name: 'AccessManagement::Group', foreign_key: :access_management_group_id, touch: true
  belongs_to :credential, class_name: 'AccessManagement::Credential', foreign_key: :access_management_credential_id
  after_destroy -> { group&.touch }
  after_commit -> { group&.touch }, on: :create
end
