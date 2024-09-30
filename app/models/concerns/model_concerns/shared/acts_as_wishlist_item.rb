# frozen_string_literal: true

module ModelConcerns::Shared::ActsAsWishlistItem
  extend ActiveSupport::Concern

  included do
    has_many :wishlist_items, as: :model, dependent: :destroy
    has_many :wished_by, through: :wishlist_items, source: :user
    scope :wished_by, ->(user) { where({ id: WishlistItem.where(user: user, model_type: klass.name).select('model_id') }) }
  end
end
