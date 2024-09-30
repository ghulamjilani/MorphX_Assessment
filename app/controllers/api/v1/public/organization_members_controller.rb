# frozen_string_literal: true

class Api::V1::Public::OrganizationMembersController < Api::V1::Public::ApplicationController
  before_action :set_organization

  def index
    scope = params[:scope] || 'presenters'
    codes = case scope
            when 'presenters'
              %i[end_session start_session]
            when 'blog'
              %i[manage_blog_post]
            when 'all'
              %i[end_session start_session manage_blog_post]
            else
              []
            end
    @organization_members = User.distinct.joins(organization_memberships: { groups_members: { group: :credentials } })
                                .where(organization_memberships: { organization_id: @organization.id, status: OrganizationMembership::Statuses::ACTIVE },
                                       access_management_credentials: { code: codes }).order(id: :asc).limit(@limit).offset(@offset)
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
