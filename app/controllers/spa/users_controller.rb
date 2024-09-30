# frozen_string_literal: true

class Spa::UsersController < Spa::ApplicationController
  def show
    redirect_to root_path, flash: { error: 'Access denied' } unless valid_user_request?
  end

  private

  def user
    @user ||= User.friendly.find(params[:id].to_s.downcase)
  end

  def valid_user_request?
    user.present? && current_ability.can?(:read, user)
  end
end
