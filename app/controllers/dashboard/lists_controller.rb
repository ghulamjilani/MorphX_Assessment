# frozen_string_literal: true

class Dashboard::ListsController < Dashboard::ApplicationController
  before_action :check_credentials
  skip_before_action :check_if_has_needed_cookie

  skip_before_action :extract_refc_from_url_into_cookie
  skip_before_action :check_if_referral_user, if: :user_signed_in?
  skip_before_action :persist_timezone_if_not_yet_specified
  skip_before_action :set_timezone
  respond_to :json

  def index
    @page = params[:page] || 1
    @order = params[:order] || :desc

    @lists = current_user.current_organization.lists.order(created_at: @order) # .page(@page).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @lists }
      format.js
    end
  end

  def new
    @list = current_user.current_organization.lists.build
  end

  def create
    @list = current_user.current_organization.lists.new(list_attributes)

    if @list.save
      @list.products.create(products_attributes) if params[:products]
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list) }
        format.json { render json: @list }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :new, flash: { error: @list.errors.full_messages.join('. ') }, status: 422 }
        format.json { render json: @list.errors.full_messages.join('. '), status: 422 }
        format.js
      end
    end
  end

  def edit
    @list = current_user.current_organization.lists.find(params[:id])
  end

  def update
    @list = current_user.current_organization.lists.find(params[:id])

    if @list.update(list_attributes)
      respond_to do |format|
        format.html { redirect_to dashboard_lists_path }
        format.json { render json: @list }
        format.js
      end
    else
      @error = @list.errors.full_messages.join('. ')
      respond_to do |format|
        format.html { redirect_to edit_dashboard_list_path(@list), flash: { error: @error }, status: 422 }
        format.json { render json: { message: @error }, status: 422 }
        format.js
      end
    end
  end

  def destroy
    current_user.current_organization.lists.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to dashboard_lists_path }
      format.json { head :ok }
      format.js { head :ok }
    end
  end

  private

  def list_attributes
    params.require(:list).permit(:name, :description)
  end

  def products_attributes
    params.require(:products).permit(:title, :description, :url, :short_description, :specifications, :price,
                                     product_image_attributes: %i[remote_original_url original])
  end

  def check_credentials
    return redirect_to dashboard_path if cannot?(:manage_product, current_user.current_organization) ||
                                         cannot?(:access_products_by_business_plan, current_user.current_organization)
  end
end
