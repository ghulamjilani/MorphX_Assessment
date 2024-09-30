# frozen_string_literal: true
FactoryBot.define do
  factory :blog_post, class: 'Blog::Post' do
    association :channel, factory: :listed_channel
    organization { channel&.organization }
    user { channel&.organizer }
    title { Forgery(:lorem_ipsum).title(random: true) }
    body { "<a href=\"#{"https://#{Forgery(:internet).domain_name}/#{Forgery(:lorem_ipsum).words(3, random: true).split.map(&:parameterize).join('/')}"}\">link</a> #{Forgery(:lorem_ipsum).paragraphs(3, random: true)}" }
    status { Blog::Post::Statuses::ALL.sample }
    after(:create) do |post|
      FactoryBot.create(:blog_post_cover, post: post) if [true, false].sample
    end
  end

  Blog::Post::Statuses::ALL.each do |status|
    factory "blog_post_#{status}".to_sym, parent: :blog_post do
      status { status }
    end
  end

  factory :aa_stub_blog_posts, parent: :blog_post
end
