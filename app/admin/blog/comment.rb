# frozen_string_literal: true

ActiveAdmin.register Blog::Comment do
  menu parent: 'Blog'

  filter :id
  filter :blog_post_id
  filter :commentable_id
  filter :commentable_type, as: :select, collection: proc { ['Blog::Comment', 'Blog::Post'] }
  filter :comments_count
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :user_id
    column :user
    column :post
    column :commentable_type
    column :commentable do |comment|
      case comment.commentable_type
      when 'Blog::Post'
        link_to(comment.commentable.title, service_admin_panel_blog_post_path(comment.commentable_id))
      when 'Blog::Comment'
        link_to(comment.commentable.body_text.first(20), service_admin_panel_blog_comment_path(comment.commentable_id))
      end
    end
    column :body
    column :featured_link_preview
    column :comments_count
    column :created_at
    column :updated_at

    actions
  end

  actions :all

  form do |f|
    f.inputs do
      f.input :user_id
      f.input :body
      f.input :featured_link_preview_id
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
