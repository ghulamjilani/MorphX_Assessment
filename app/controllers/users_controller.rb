# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:video_on_profile]

  def video_on_profile
    v = Video.where(user_id: current_user.id).find(params[:video_id])
    v.update_attribute :show_on_profile, (params[:video_action] == 'show')
    head :ok
  rescue StandardError
    head 404
  end

  def fetch_avatar
    users = User.where(%(lower(users.email) = lower(?)), params[:email]).to_a
    res = (users.size == 1) ? users.first.medium_avatar_url : ''
    respond_to do |format|
      format.html { render plain: res }
      format.json { render json: { url: res } }
    end
  end

  def home
    redirect_to User.find(params[:id]).relative_path
  end

  private

  def load_personal_space_user
    @user = User.friendly.find(user_slug)
  end

  def user_slug
    CGI.unescape(params[:raw_slug])
  end
end
