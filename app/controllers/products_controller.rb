# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :authenticate_user!, except: %i[fetch_products search_by_upc]
  before_action :load_list, except: %i[fetch fetch_products search_by_upc]
  respond_to :json

  def index
    @list = current_user.current_organization.lists.find(params[:list_id])

    return render json: [] unless @list

    render json: @list.products
  end

  def create
    @product = @list.products.find_or_initialize_by(url: params[:product][:url])
    @product.attributes = product_attributes
    if @product.save
      @product.update(image_attributes) if image_attributes
      render json: @product.to_json(user: @list.user)
    else
      render json: @product.errors.full_messages.join('. '), status: 422
    end
  end

  def update
    @product = @list.products.find(params[:id])
    if @product.update(product_attributes)
      if image_attributes[:product_image_attributes] && image_attributes[:product_image_attributes][:original] && image_attributes
        @product.update(image_attributes)
      end
      render json: @product.to_json(user: @list.user)
    else
      render json: @product.errors.full_messages.join('. '), status: 422
    end
  end

  def destroy
    @list.lists_products.where(product_id: params[:id]).destroy_all
    head :ok
  end

  def fetch
    # product = Product.find_by(url: params[:product][:url])
    # return render(json: product) if product
    explorer = Sales::ProductInfo.new(current_user)
    result = explorer.fetch(url: params[:product][:url])
    render json: result
  end

  def fetch_products
    case params[:model_type].downcase
    when 'session'
      session = Session.find(params[:model_id])
      @lists = begin
        session.organization.lists.includes(:products)
      rescue StandardError
        []
      end
      selected_list = session.lists.first
      if selected_list
        @lists.each { |l| l.selected = (l.id == selected_list.id) }
      else
        @lists.each { |l| l.selected = false }
      end
    when 'replay'
      @lists = Video.find(params[:model_id]).lists.includes(:products)
      @lists.each { |l| l.selected = true }
    when 'recording'
      @lists = Recording.find(params[:model_id]).lists.includes(:products)
      @lists.each { |l| l.selected = true }
    end
    render json: @lists
  end

  def search_by_upc
    return unless current_user && params[:barcode]

    @product = Product.where('barcodes ILIKE ?', "%#{params[:barcode]}%").limit(1).first
    unless @product
      explorer = Sales::ProductInfo.new(current_user)
      result = explorer.lookup(barcode: params[:barcode])
      if result.present?
        params[:product] = ActionController::Parameters.new result
        @product = Product.find_or_initialize_by(url: scanned_attributes[:url])
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
        message = 'Product already in list'
        resp = { json: { message: message }, status: 409 }
      else
        @list.products << @product
        @session = params[:session_id].present? ? Session.find_by(id: params[:session_id]) : Session.live_now.where(presenter_id: current_user.presenter_id).first
        if @session&.room
          @session.room.product_scanned(@product, @list)
        end
        message = "Product added to #{@list.name}"
        resp = { json: { message: message, product: @product, list: { id: @list.id, name: @list.name } }, status: 200 }
      end
    elsif @product
      message = @product.errors.full_messages
      resp = { json: { message: message }, status: 422 }
    else
      message = 'No product found'
      resp = { json: { message: message }, status: 404 }
    end
    respond_to do |format|
      format.json { render(resp) }
      format.html { redirect_back fallback_location: root_path, flash: message }
    end
  end

  private

  def load_list
    @list = current_user.current_organization.lists.find(params[:list_id])
  end

  def product_attributes
    params.require(:product).permit(:title, :description, :url, :short_description, :specifications, :price).tap do |p|
      if p[:price]
        Monetize.assume_from_symbol = true
        p[:price] = Monetize.parse(p[:price])
        if p[:url] && (@product.new_record? || @product.url != p[:url] || @product.affiliate_url.blank?)
          parser = Sales::ProductUrl.new(p[:url], current_user)
          parser.extract
          p[:partner] = parser.partner
          p[:base_url] = parser.direct_url.to_s
          p[:affiliate_url] = parser.affiliate_url.to_s
        end
      end
    end
  end

  def image_attributes
    params.require(:product).permit(product_image_attributes: %i[remote_original_url original])
  end

  def scanned_attributes
    params.require(:product).permit(:partner, :barcodes, :title, :description, :url, :short_description,
                                    :specifications, :price_cents, :price_currency, :raw_info,
                                    product_image_attributes: [:remote_original_url],
                                    stores_attributes: %i[min_price_cents max_price_cents price_currency
                                                          category manufacturer advertiser url])
  end
end
