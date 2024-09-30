# frozen_string_literal: true

class Spa::Blog::PostsController < Spa::Blog::ApplicationController
  def index
    if params[:organization_id].present? && !valid_organization_request?
      redirect_to root_path,
                  flash: { error: 'Access denied' }
    end
    # @posts = organization.blog_posts.visible_for_user(current_user)
  end

  def show
    return redirect_to(root_path, flash: { error: 'Page not found' }) unless valid_organization_request?

    unless valid_post_request?
      return redirect_to(spa_organization_blog_posts_path(organization),
                         flash: { error: 'Post not found' })
    end

    unless current_ability.can?(
      :read, post
    )
      redirect_to(spa_organization_blog_posts_path(post.organization),
                  flash: { error: 'Access denied' })
    end
  end

  private

  def organization
    @post_organization ||= Organization.where(slug: params[:organization_id].to_s.downcase).first
  end

  def post
    @post ||= begin
      Blog::Post.where(organization_id: organization&.id).friendly.find(params[:id])
    rescue StandardError
      nil
    end
  end

  def valid_post_request?
    post.present?
  end

  def valid_organization_request?
    organization.present?
  end
end
