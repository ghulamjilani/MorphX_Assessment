# frozen_string_literal: true
class Shop::AttachedList < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  MODEL_TYPES = %w[Channel Recording Session User Video].freeze

  belongs_to :list
  belongs_to :model, polymorphic: true
  validates :model_type, presence: true
end
