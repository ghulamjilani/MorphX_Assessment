# frozen_string_literal: true
FactoryBot.define do
  factory :video do
    duration { 1 }
    size { 1 }
    filename { 'MyString' }
    room { create(:recorded_session).room }
    association :user, factory: :user
    platform_ident { 'MyString' }
    storage_ident { 'MyString' }
    status { 'done' }
    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
    ffmpegservice_starts_at { 2.days.ago.utc.to_fs(:rfc3339) }
  end

  factory :video_found, parent: :video do
    status { ::Video::Statuses::FOUND }
  end

  factory :video_found_no_room, parent: :video_found do
    user { nil }
    room { nil }
  end

  factory :video_transfer, parent: :video do
    status { ::Video::Statuses::TRANSFER }
  end

  factory :video_downloaded, parent: :video do
    status { ::Video::Statuses::DOWNLOADED }
  end

  factory :video_original_verified, parent: :video_downloaded do
    status { ::Video::Statuses::ORIGINAL_VERIFIED }
  end

  factory :video_transcoded, parent: :video_downloaded do
    status { ::Video::Statuses::TRANSCODED }
    hls_preview { "#{s3_path}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s + rand(9999).to_s)}/playlist.m3u8" }
    hls_main { "#{s3_path}/#{Digest::MD5.hexdigest(hls_preview)}/playlist.m3u8" }
  end

  factory :seed_video, parent: :video do
    duration { (15 * 60 * 1000..180 * 60 * 1000).to_a.sample }
    size { 100_500 }
    filename { 'roomid16365_userid319_14415717080310605.mp4' }
    status { 'done' }
    show_on_profile { true }
    show_on_home { true }
  end

  factory :video_published, parent: :seed_video do
    published { Time.zone.now }
  end

  factory :video_published_on_listed_channel, parent: :video_published do
    room { create(:room_on_listed_channel) }
  end

  factory :video_with_error, parent: :video do
    status { 'error' }
  end

  factory :aa_stub_videos, parent: :video
end
