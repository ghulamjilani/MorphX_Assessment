# frozen_string_literal: true

class Api::V1::Organization::UsersController < Api::V1::Organization::ApplicationController
  before_action :set_user, except: %i[index create]

  def index
    query = if params['organization_id'].blank?
              current_organization.employees
            else
              ::Organization.find(params['organization_id']).employees
            end
    @count = query.count
    @users = query.limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    ::User.transaction do
      @user = User.new(user_params)
      @user.parent_organization_id = current_organization.id
      @user.before_create_generic_callbacks_without_skipping_validation
      @user.save!
      Presenter.create!(user: @user)
      @organization_membership = OrganizationMembership.create!(
        { user: @user, organization: current_organization,
          status: OrganizationMembership::Statuses::ACTIVE }.merge organization_membership_params
      )
    end
    render :show
  end

  def update
    raise 'not implemented'
  end

  def destroy
    raise 'not implemented'
  end

  private

  def set_user
    @user = (action_name.to_s == 'show') ? ::User.find(params[:id]) : current_organization.employees.find(params[:id])
    @organization_membership = current_organization.organization_memberships_active.find_by(user_id: @user.id) if @user
  end

  def user_params
    params.require(:user).permit(
      :birthdate,
      :email,
      :password,
      :first_name,
      :gender,
      :last_name
    )
  end

  def organization_membership_params
    params.require(:organization_membership).permit(:role, :position)
  end
end
