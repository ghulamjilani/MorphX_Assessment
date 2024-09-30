# frozen_string_literal: true

class BlogMailerPreview < ApplicationMailerPreview
  def new_mention_in_post
    blog_post = Blog::Post.published.order('RANDOM()').first || FactoryBot.create(:blog_post_published)
    mentioned_user_id = User.order('RANDOM()').first.id
    BlogMailer.new_mention_in_post(blog_post.id, mentioned_user_id)
  end

  def new_mention_in_comment
    blog_comment = Blog::Comment.order('RANDOM()').first || FactoryBot.create(:blog_comment)
    mentioned_user_id = User.order('RANDOM()').first.id
    BlogMailer.new_mention_in_comment(blog_comment.id, mentioned_user_id)
  end
end
