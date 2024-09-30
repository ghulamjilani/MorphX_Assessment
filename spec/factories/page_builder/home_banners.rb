# frozen_string_literal: true
FactoryBot.define do
  factory :home_banner, class: '::PageBuilder::HomeBanner' do
    file do
      if Rails.env.test?
        File.open(ImageSample.for_size('300x150'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/channel/*')].sample)
      end
    end
  end

  factory :aa_stub_page_builder_home_banners, parent: :home_banner
end
