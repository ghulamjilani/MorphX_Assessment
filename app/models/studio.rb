# frozen_string_literal: true
class Studio < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :organization

  has_many :studio_rooms, dependent: :destroy
  has_many :ffmpegservice_accounts, through: :studio_rooms

  validates :name, uniqueness: { scope: :organization_id }, presence: true, allow_blank: false, allow_nil: false
end
