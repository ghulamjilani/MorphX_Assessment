# frozen_string_literal: true
class Blog::CommentsLinkPreviews < Blog::ApplicationRecord
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :blog_comment, class_name: 'Blog::Comment'
  belongs_to :link_preview
end
