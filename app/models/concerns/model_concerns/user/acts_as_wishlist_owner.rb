# frozen_string_literal: true

module ModelConcerns::User::ActsAsWishlistOwner
  extend ActiveSupport::Concern

  included do
    has_many :wishlist_items, dependent: :destroy
  end

  def has_in_wishlist?(model)
    Rails.cache.fetch("has_in_wishlist/#{id}/#{model.id}/#{model.class.name}") do
      WishlistItem.exists?(model_id: model.id, model_type: model.class.name, user: self)
    end
  end

  def remove_from_wishlist(model)
    WishlistItem.where(model_id: model.id, model_type: model.class.name, user: self).destroy_all
    Rails.cache.delete("has_in_wishlist/#{id}/#{model.id}/#{model.class.name}")
  end

  def add_to_wishlist(model)
    WishlistItem.create(model: model, user: self)
    Rails.cache.delete("has_in_wishlist/#{id}/#{model.id}/#{model.class.name}")

    # if session.presenter.present?
    #   Immerss::SessionMultiFormatMailer.new.wishlist_session(id, session.id).deliver
    # end
  end
end
