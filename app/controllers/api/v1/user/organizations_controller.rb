# frozen_string_literal: true

class Api::V1::User::OrganizationsController < Api::V1::ApplicationController
  before_action :set_organization, only: %i[update show]

  def index
    @organizations = current_user.all_organizations
  end

  def update
    @organization.update!(organization_params)
    render :show
  end

  def show
  end

  def set_current
    @organization = ::Organization.joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = organizations.id))
                                  .where('organizations.user_id = :id OR organization_memberships.user_id = :id', id: current_user.id).find(params[:id])

    render_json 403 and return unless current_ability.can?(:set_current, @organization)

    current_user.current_organization_id = @organization.id
    current_user.save(validate: false)
    render :show
  end

  private

  def set_organization
    render_json 404 unless (@organization = current_user.current_organization)
  end

  def organization_params
    params.require(:organization).permit(:name, :description)
  end
end
