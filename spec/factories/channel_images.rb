# frozen_string_literal: true
FactoryBot.define do
  factory :channel_image do
    association :channel, factory: :channel
    image do
      if Rails.env.test?
        File.open(ImageSample.for_size('300x150'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/channel/*')].sample)
      end
    end
  end

  factory :main_channel_image, parent: :channel_image do
    is_main { true }

    image do
      if Rails.env.test?
        File.open(ImageSample.for_size('415x115'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/channel/*')].sample)
      end
    end
  end
  factory :aa_stub_channel_images, parent: :channel_image
end
