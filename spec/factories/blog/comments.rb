# frozen_string_literal: true
FactoryBot.define do
  factory :blog_comment, class: 'Blog::Comment' do
    user { create(:user) }
    commentable { create(:blog_post_published) }
    body { Forgery(:lorem_ipsum).paragraphs(2, random: true) }
  end

  factory :blog_comment_on_comment, parent: :blog_comment do
    commentable { create(:blog_comment) }
  end

  factory :aa_stub_blog_comments, parent: :blog_comment
end
