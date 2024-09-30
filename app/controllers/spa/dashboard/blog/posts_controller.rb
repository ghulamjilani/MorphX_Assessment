# frozen_string_literal: true

class Spa::Dashboard::Blog::PostsController < Spa::Dashboard::Blog::ApplicationController
  def index
  end

  def show
    redirect_to root_path, flash: { error: 'Access denied' } unless valid_post_request?
  end

  def new
  end

  private

  def post
    @post ||= Blog::Post.visible_for_user(current_user).find_by(id: params[:id])
  end

  def valid_post_request?
    post.present? && current_ability.can?(:edit, post)
  end
end
