# frozen_string_literal: true

class Api::V1::User::StudioRoomsController < Api::V1::User::ApplicationController
  before_action :set_studio_room, only: %i[show update destroy]
  before_action :authorization_for_own_organization

  def index
    query = own_organization.studio_rooms
    query = query.where(studio_id: params[:studio_id]) if params[:studio_id].present?

    @count = query.count

    order_by = %w[id name created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @studio_rooms = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    @studio_room = own_organization.studios.find(params[:studio_id]).studio_rooms.create!(studio_room_params)
    render :show
  end

  def update
    @studio_room.update!(studio_room_params)
    render :show
  end

  def destroy
    @studio_room.destroy!
    render :show
  end

  private

  def set_studio_room
    @studio_room = own_organization.studio_rooms.find(params[:id])
  end

  def studio_room_params
    params.require(:studio_room).permit(
      :name,
      :description
    )
  end
end
