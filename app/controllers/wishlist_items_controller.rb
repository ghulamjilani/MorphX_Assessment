# frozen_string_literal: true

class WishlistItemsController < Dashboard::ApplicationController
  def toggle
    unless WishlistItem::SUPPORTED_MODELS.include?(params[:model_type])
      raise 'Model not supported'
    end

    @model = params[:model_type].singularize.classify.constantize.find(params[:model_id])
    authorize!(:have_in_wishlist, @model)

    if current_user.has_in_wishlist?(@model)
      current_user.remove_from_wishlist(@model)
      @has_in_wishlist_now = false
    else
      current_user.add_to_wishlist(@model)
      @has_in_wishlist_now = true
    end
  end
end
