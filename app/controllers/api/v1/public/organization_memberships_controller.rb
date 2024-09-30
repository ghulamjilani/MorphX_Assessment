# frozen_string_literal: true

class Api::V1::Public::OrganizationMembershipsController < Api::V1::Public::ApplicationController
  def index
    query = OrganizationMembership.active.participants.where(nil)
    query = query.where(organization_id: params[:organization_id]) if params[:organization_id].present?
    @count = query.count

    order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @organization_memberships = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end
end
