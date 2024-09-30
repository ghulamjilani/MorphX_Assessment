# frozen_string_literal: true

class Api::V1::Organization::OrganizationMembershipsController < Api::V1::Organization::ApplicationController
  before_action :set_organization_membership, only: [:show]

  def index
    organization_id = params[:organization_id] || current_organization.id
    query = OrganizationMembership.participants.where(organization_id: organization_id)

    @count = query.count

    order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @organization_memberships = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
  end

  private

  def set_organization_membership
    @organization_membership = OrganizationMembership.find(params[:id])
  end
end
