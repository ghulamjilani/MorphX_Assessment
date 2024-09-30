# frozen_string_literal: true

class ListsController < ApplicationController
  before_action :authenticate_user!
  respond_to :json

  def index
    @page = params[:page] || 1
    @lists = current_user.current_organization.lists.order(updated_at: :desc).page(@page).per(10).includes(products: :product_image)

    render json: @lists
  end

  def create
    @list = current_user.current_organization.lists.new(list_attributes)

    if @list.save
      @list.products.create(products_attributes) if params[:products]
      render json: @list
    else
      render json: @list.errors.full_messages.join('. '), status: 422
    end
  end

  def update
    @list = current_user.current_organization.lists.find(params[:id])

    if @list.update(list_attributes)
      render json: @list
    else
      render json: @list.errors.full_messages.join('. '), status: 422
    end
  end

  def destroy
    current_user.current_organization.lists.find(params[:id]).destroy
    head :ok
  end

  private

  def list_attributes
    params.require(:list).permit(:name, :description, :url)
  end

  def products_attributes
    params.require(:products).permit(:title, :description, :url, :short_description, :specifications, :price,
                                     product_image_attributes: %i[remote_original_url original])
  end
end
