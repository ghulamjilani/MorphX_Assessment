# frozen_string_literal: true

class Api::V1::Organization::MindBody::StaffsController < Api::V1::Organization::ApplicationController
  before_action :set_staff, only: %i[show update]

  def show
  end

  def update
    @staff.update(staff_params)
    render :show
  end

  private

  def set_staff
    @staff = MindBodyDb::Staff.find(params[:id])
  end

  def staff_params
    params.permit(:user_id)
  end
end
