# frozen_string_literal: true

class Api::V1::Blog::CommentsController < Api::V1::Blog::ApplicationController
  skip_before_action :authorization_only_for_user, only: %i[index show]

  def index
    query = Blog::Comment.visible_for_user(current_user)

    query = query.where(blog_post_id: params[:post_id]) if params[:post_id].present?
    query = query.where(user_id: params[:user_id]) if params[:user_id].present?

    if params[:commentable_id].present? && params[:commentable_type].present?
      query = query.where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type])
    end

    @count = query.count

    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'updated_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @comments = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:user)
  end

  def show
    @comment = Blog::Comment.visible_for_user(current_user).find_by(id: params[:id])
    unless @comment.present? && current_ability.can?(
      :read, @comment
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.comments.errors.read_forbidden'))
    end
  end

  def create
    commentable = if params[:post_id].present?
                    Blog::Post.visible_for_user(current_user).find_by(id: params[:post_id])
                  elsif create_comment_params[:commentable_type].present? && create_comment_params[:commentable_id].present?
                    create_comment_params[:commentable_type].classify.constantize.visible_for_user(current_user).find_by(id: create_comment_params[:commentable_id])
                  end

    unless commentable.present? && current_ability.can?(
      :comment, commentable
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.comments.errors.create_forbidden'))
    end

    @comment = commentable.comments.build(create_comment_params)
    @comment.user = current_user
    @comment.save!
    render :show
  end

  def update
    @comment = current_user.blog_comments.find_by(id: params[:id])
    unless @comment.present? && current_ability.can?(
      :edit, @comment
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.comments.errors.update_forbidden'))
    end

    @comment.update!(update_comment_params)
    render :show
  end

  def destroy
    @comment = Blog::Comment.find_by(id: params[:id])
    unless @comment.present? && current_ability.can?(
      :destroy, @comment
    )
      raise(AccessForbiddenError,
            I18n.t('controllers.api.v1.blog.comments.errors.destroy_forbidden'))
    end

    @comment.destroy!
    render :show
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::Blog::CommentAbility.new(current_user).merge(::AbilityLib::Blog::PostAbility.new(current_user))
  end

  def create_comment_params
    params.require(:comment).permit(
      :commentable_id,
      :commentable_type,
      :body,
      :featured_link_preview_id
    )
  end

  def update_comment_params
    params.require(:comment).permit(
      :body,
      :featured_link_preview_id
    ).tap do |attrs|
      attrs[:edited_at] = Time.now.utc
    end
  end
end
