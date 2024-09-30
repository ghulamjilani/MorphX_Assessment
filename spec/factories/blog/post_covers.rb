# frozen_string_literal: true
FactoryBot.define do
  factory :blog_post_cover, class: 'Blog::PostCover' do
    association :post, factory: :blog_post_published
    image do
      if Rails.env.test?
        File.open(ImageSample.for_size('300x300'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/organization_covers/*')].sample)
      end
    end
  end

  factory :aa_stub_blog_post_covers, parent: :blog_post_cover
end
