# frozen_string_literal: true
FactoryBot.define do
  factory :blog_image, class: 'Blog::Image' do
    organization { create(:organization) }
    image do
      if Rails.env.test?
        File.open(ImageSample.for_size('1x1'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/organization_covers/*')].sample)
      end
    end
  end

  factory :blog_image_attached, parent: :blog_image do
    blog_post { create(:blog_post_published) }
    organization { blog_post.organization }
  end
end
