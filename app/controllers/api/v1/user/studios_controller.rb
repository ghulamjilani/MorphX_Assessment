# frozen_string_literal: true

class Api::V1::User::StudiosController < Api::V1::User::ApplicationController
  before_action :set_studio, only: %i[show update destroy]
  before_action :authorization_for_own_organization

  def index
    query = own_organization.studios
    @count = query.count

    order_by = %w[id name created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @studios = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    @studio = own_organization.studios.create!(studio_params)
    render :show
  end

  def update
    @studio.update!(studio_params)
    render :show
  end

  def destroy
    @studio.destroy
    render :show
  end

  private

  def set_studio
    @studio = own_organization.studios.find(params[:id])
  end

  def studio_params
    params.require(:studio).permit(
      :name,
      :description,
      :phone,
      :address
    )
  end
end
