# frozen_string_literal: true

class Api::V1::User::UserSearchController < Api::V1::ApplicationController
  def index
    query = User.not_fake.not_deleted
    if params[:query].to_s.strip.present?
      query = query.where('email ILIKE :search', search: "%#{params[:query]}%")
    end
    @count = query.count

    order_by = %w[id display_name created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @users = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end
end
