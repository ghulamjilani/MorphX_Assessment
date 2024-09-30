# frozen_string_literal: true

class Api::V1::Blog::PostsController < Api::V1::Blog::ApplicationController
  include ControllerConcerns::TracksViews

  skip_before_action :authorization_only_for_user, only: %i[index show]
  before_action :set_post, only: %i[show vote]

  def index
    query = if params[:resource_type].present? && params[:resource_id].present?
              resource = params[:resource_type].classify.constantize.find(params[:resource_id])
              resource.blog_posts
            elsif params[:resource_type].present? && params[:resource_slug].present?
              resource = params[:resource_type].classify.constantize.friendly.find(params[:resource_slug])
              resource.blog_posts
            else
              ::Blog::Post
            end

    query = if params[:scope] == 'edit'
              query.editable_by_user(current_user)
            else
              query.visible_for_user(current_user)
            end

    query = if params[:status].blank?
              query.not_archived
            else
              query.where(status: params[:status])
            end

    if params[:date_from] && params[:date_to]
      query = query.where(created_at: params[:date_from]..params[:date_to])
    elsif params[:date_from]
      query = query.where('blog_posts.created_at >= ?', params[:date_from])
    elsif params[:date_to]
      query = query.where('blog_posts.created_at <= ?', params[:date_to])
    end

    @count = query.count

    params[:order_by] = 'cached_votes_up' if params[:order_by].present? && params[:order_by] == 'likes_count'

    order_by = if %w[created_at updated_at published_at views_count
                     cached_votes_up].include?(params[:order_by])
                 params[:order_by]
               else
                 'created_at'
               end
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @posts = query.order(Arel.sql("#{order_by} #{order}"))
                  .limit(@limit)
                  .offset(@offset)
                  .preload(
                    :cover,
                    :user,
                    :channel,
                    :link_previews,
                    :featured_link_preview,
                    :organization
                  )
  end

  def show
    track_view(@post) if can?(:track_view, @post)
  end

  def new
    if current_user.current_organization.blank?
      raise(AccessForbiddenError, I18n.t('controllers.api.v1.blog.posts.errors.create_forbidden'))
    elsif current_user == current_user.current_organization.user
      @channels = current_user.current_organization.channels.approved.not_archived
    else
      @channels = current_user.organization_channels_with_credentials(current_user.current_organization, %i[manage_blog_post moderate_blog_post]).approved.not_archived
    end

    @channels = @channels.order(title: :asc)
  end

  def create
    channel = current_user.all_channels.find_by(id: create_post_attributes[:channel_id])
    unless channel.present? && current_ability.can?(
      :manage_blog_post, channel
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.posts.errors.create_forbidden'))
    end

    @post = channel.blog_posts.build
    @post.attributes = create_post_attributes
    @post.cover&.valid?
    @post.user_id = current_user.id
    @post.status = ::Blog::Post::Statuses::PUBLISHED if create_post_attributes[:status].blank?
    @post.save!
    if params[:image_id].present?
      params[:image_id] = params[:image_id].split(',').map(&:to_i) if params[:image_id].is_a?(String)
      @post.organization.blog_images.not_attached.where(id: params[:image_id]).update_all(blog_post_id: @post.id)
    end
    render :show
  end

  def update
    @post = ::Blog::Post.friendly.find(params[:id])
    unless current_ability.can?(
      :edit, @post
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.posts.errors.update_forbidden'))
    end

    @post.update!(update_post_attributes)
    if params[:image_id].present?
      params[:image_id] = params[:image_id].split(',').map(&:to_i) if params[:image_id].is_a?(String)
      @post.organization.blog_images.not_attached.where(id: params[:image_id]).update_all(blog_post_id: @post.id)
    end
    render :show
  end

  def destroy
    @post = ::Blog::Post.friendly.find(params[:id])
    unless current_ability.can?(
      :edit, @post
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.posts.errors.destroy_forbidden'))
    end

    @post.destroy!
    render :show
  end

  def vote
    current_user.liked?(@post) ? current_user.unlike(@post) : current_user.like(@post)
    OrganizationBlogChannel.broadcast 'post_likes_count_updated', { id: @post.id, likes_count: @post.likes_count }
    render :show
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::Blog::PostAbility.new(current_user).tap do |ability|
      ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
      ability.merge(::AbilityLib::ChannelAbility.new(current_user))
    end
  end

  def set_post
    query = ::Blog::Post.preload(:votes_for, channel: %i[cover logo])
    @post = params[:slug].to_i.zero? ? query.find(params[:id]) : query.friendly.find(params[:id])
    unless @post.present? && current_ability.can?(:read, @post)
      raise(AccessForbiddenError, I18n.t('controllers.api.v1.blog.posts.errors.read_forbidden'))
    end
  end

  def create_post_attributes
    params.require(:post).permit(
      :channel_id,
      :body,
      :title,
      :status,
      :tag_list,
      :featured_link_preview_id,
      :hide_author,
      :published_at,
      cover_attributes: %i[crop_x crop_y crop_w crop_h rotate image]
    ).tap do |p|
      p.delete(:cover_attributes) unless p[:cover_attributes] && p[:cover_attributes][:image]
    end
  end

  def update_post_attributes
    params.require(:post).permit(
      :channel_id,
      :body,
      :title,
      :status,
      :tag_list,
      :featured_link_preview_id,
      :hide_author,
      :published_at,
      cover_attributes: %i[crop_x crop_y crop_w crop_h rotate image]
    ).tap do |attrs|
      attrs[:edited_at] = Time.now.utc
    end
  end
end
