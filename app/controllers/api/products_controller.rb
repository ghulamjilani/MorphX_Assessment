# frozen_string_literal: true

class Api::ProductsController < Api::ApplicationController
  include ActionView::Rendering

  def search_by_upc
    return unless current_user && params[:barcode]

    @product = ::Shop::Product.where('barcodes ILIKE ?', "%#{params[:barcode]}%").limit(1).first
    unless @product
      explorer = Sales::ProductInfo.new(current_user)
      result = explorer.lookup(barcode: params[:barcode])
      if result.present?
        params[:product] = ActionController::Parameters.new result
        @product = ::Shop::Product.find_or_initialize_by(url: scanned_attributes[:url])
        if @product.new_record?
          @product.attributes = scanned_attributes
          @product.save
        end
      end
    end
    if @product && @product.errors.empty?
      @list = current_user.current_organization.lists.find_by(id: params['list_id']) if params[:list_id].present?
      @list ||= current_user.current_organization.lists.find_or_create_by(name: 'Scans')
      if @list.products.exists?(id: @product.id)
        render json: { message: 'Product already in list' }, status: 409
      else
        @list.products << @product
        @session = params[:session_id].present? ? Session.live_now.find_by(id: params[:session_id]) : Session.live_now.where(presenter_id: current_user.presenter_id).first
        if @session&.room
          @session.room.product_scanned(@product, @list)
        end
        render json: { product: @product.to_json(user: @list.user), list: { id: @list.id, name: @list.name }.to_json }
      end
    elsif @product
      render json: { message: @product.errors.full_messages }, status: 422
    else
      render json: { message: 'No product found' }, status: 404
    end
  end

  private

  def scanned_attributes
    params.require(:product).permit(:partner, :barcodes, :title, :description, :url, :short_description,
                                    :specifications, :price_cents, :price_currency, :raw_info,
                                    product_image_attributes: [:remote_original_url],
                                    stores_attributes: %i[min_price_cents max_price_cents price_currency
                                                          category manufacturer advertiser url])
  end
end
