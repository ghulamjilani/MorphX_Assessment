# frozen_string_literal: true
class Blog::PostsLinkPreviews < Blog::ApplicationRecord
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :blog_post, class_name: 'Blog::Post'
  belongs_to :link_preview
end
