# frozen_string_literal: true
FactoryBot.define do
  factory :product_image, class: 'Shop::ProductImage' do
    association :product, factory: :product
    original do
      if Rails.env.test?
        File.open(ImageSample.for_size('300x150'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/channel/*')].sample)
      end
    end
  end

  factory :aa_stub_product_images, parent: :product_image
end
