# frozen_string_literal: true
class WishlistItem < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  SUPPORTED_MODELS = %w[Session Video Recording].freeze
  belongs_to :user
  belongs_to :model, polymorphic: true

  validates :user, presence: true
  validates :model_id, presence: true, uniqueness: { scope: %i[user_id model_type] }
  validates :model_type, presence: true
end
