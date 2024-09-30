# frozen_string_literal: true
class StudioRoom < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :studio
  has_one :ffmpegservice_account, dependent: :nullify

  delegate :organization, to: :studio, allow_nil: false

  validates :name, uniqueness: { scope: :studio_id }, presence: true, allow_blank: false, allow_nil: false
end
