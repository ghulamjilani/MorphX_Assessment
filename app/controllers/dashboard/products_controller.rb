# frozen_string_literal: true

class Dashboard::ProductsController < Dashboard::ApplicationController
  # before_action :check_subscription
  before_action :check_credentials
  before_action :load_list
  respond_to :json

  def index
    @order = params[:order] || 'desc'
    @products = @list.products.order(created_at: @order)

    respond_to(&:js)
  end

  def edit
    @product = @list.products.find(params[:id])
    respond_to(&:js)
  end

  def create
    @product = current_user.current_organization.products.find_or_initialize_by(url: params[:product][:url])

    @product.attributes = product_attributes
    if @product.save
      @product.update(image_attributes) if image_attributes
      @product.lists << @list
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list), flash: { message: 'Product added!' } }
        # format.json {render @product}
        format.js
      end
    else
      @error = @product.errors.full_messages.join('. ')
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list), flash: { error: @error } }
        # format.json {render json: {message: @error}, status: 422}
        format.js
      end
    end
  end

  def update
    @product = @list.products.find(params[:id])
    if @product.update(product_attributes)
      if image_attributes[:product_image_attributes] && image_attributes[:product_image_attributes][:original] && image_attributes
        @product.update(image_attributes)
      end
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list), flash: { message: 'Product updated!' } }
        format.json { render @product }
        format.js
      end
    else
      @error = @product.errors.full_messages.join('. ')
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list), flash: { error: @error } }
        format.json { render json: { message: @error }, status: 422 }
        format.js
      end
    end
  end

  def destroy
    @list.lists_products.where(product_id: params[:id]).destroy_all
    respond_to do |format|
      format.json { render json: params[:id] }
      format.js
    end
  end

  # get product data from diffbot and other partners
  def search_by_url
    unless current_user
      return render(json: 'You need to sign in', status: 403)
      respond_to do |format|
        format.json { render json: 'You need to sign in', status: 403 }
        format.html { redirect_to root_path, flash: { error: 'You need to sign in' }, status: 403 }
      end and return
    end
    @product = @list.products.find_by(url: params[:url])
    if @product
      respond_to do |format|
        format.json { render @product }
        format.js { render 'dashboard/products/already_added' }
      end and return
    end

    explorer = Sales::ProductInfo.new(current_user)
    @result = explorer.fetch(url: params[:url])
    if @result.blank?
      respond_to do |format|
        format.json { render json: { message: 'No product found' }, status: 404 }
        format.js { render 'dashboard/products/empty_result' }
        format.html { redirect_back fallback_location: root_path, flash: { error: 'No product found' } }
      end
    else
      @product = ::Shop::Product.new.tap do |p|
        p.title = @result.title
        p.description = @result.description
        p.short_description = @result.short_description
        p.specifications = @result.specifications
        p.url = @result.url
        p.price = @result.price
        p.build_product_image
        p.product_image.remote_original_url = @result.images.to_a[0]
        p.raw_info = @result.to_json
      end
      respond_to do |format|
        format.json { render @result }
        format.js { render 'dashboard/products/search_result' }
      end
    end
  end

  # get product data by barcode from barcodelookup.com
  def search_by_upc
    return unless current_user && params[:barcode]

    @product = @list.products.where('barcodes ILIKE ?', "%#{params[:barcode]}%").limit(1).first
    unless @product
      explorer = Sales::ProductInfo.new(current_user)
      @result = explorer.lookup(barcode: params[:barcode])
      if @result.present?
        params[:product] = ActionController::Parameters.new @result
        @product = @list.products.find_or_initialize_by(url: scanned_attributes[:url])
        if @product.new_record?
          @product.attributes = scanned_attributes
        end
      end
    end
    if @product
      respond_to do |format|
        format.json { render @result }
        format.js { render 'dashboard/products/search_result' }
        format.html { redirect_back fallback_location: root_path }
      end
    else
      respond_to do |format|
        format.json { render json: { message: 'No product found' }, status: 404 }
        format.js { render 'dashboard/products/empty_result' }
        format.html { redirect_back fallback_location: root_path, flash: { error: 'No product found' } }
      end
    end
  end

  private

  def load_list
    @list = current_user.current_organization.lists.find(params[:list_id])
  end

  def check_credentials
    return redirect_to dashboard_path if cannot?(:manage_product, current_user.current_organization)
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

  def check_subscription
    if cannot?(:access_products_by_business_plan, current_user.current_organization)
      respond_to do |format|
        format.json { render_json(403, 'Access Denied') }
        format.js { render_json(403, 'Access Denied') }
        format.html { redirect_to spa_dashboard_business_plan_index_path }
      end and return
    end
  end
end
