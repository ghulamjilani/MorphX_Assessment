# frozen_string_literal: true
class AccessManagement::Type < AccessManagement::ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  validates :name, presence: true
  has_many :credentials, -> { active }, class_name: 'AccessManagement::Credential', foreign_key: :access_management_type_id
end
