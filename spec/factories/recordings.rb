# frozen_string_literal: true
FactoryBot.define do
  factory :recording do
    channel { create(:listed_channel) }
    provider { 'google' }
    hide { false }
    vid { '123' }
    title { Forgery(:lorem_ipsum).words(3) }
    description { Forgery(:lorem_ipsum).words(8) }
    sequence(:url) { |n| "http://bit.ly/2bj-#{n}" }
    purchase_price { 0.0 }
    show_on_home { true }
    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
    duration { 100_500 }

    after(:build) do |recording|
      recording.file.attach(io: File.open(Rails.root.join('spec/fixtures/active_storage/sample.mp4')), filename: 'sample.mp4', content_type: 'video/mp4')
    end
  end

  factory :recording_transcoded, parent: :recording do
    status { :transcoded }
    hls_main { "#{s3_root_path}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s + rand(9999).to_s)}/playlist.m3u8" }
    hls_preview { "#{s3_root_path}/#{Digest::MD5.hexdigest(hls_main)}/playlist.m3u8" }
  end

  factory :recording_done, parent: :recording do
    status { :done }
  end

  factory :recording_published, parent: :recording_done do
    published { Time.zone.now }
  end

  factory :recording_paid, parent: :recording_published do
    purchase_price { 9.99 }
  end

  factory :aa_stub_recordings, parent: :recording
end
