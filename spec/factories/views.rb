# frozen_string_literal: true
FactoryBot.define do
  factory :view do
    association :viewable, factory: %i[video_published recording_published immersive_session].sample
    ip_address { Forgery(:internet).ip_v4 }
    user { create(:user) }
    controller_name { 'not_found_or_title_parameterized' }
    action_name { 'user_or_channel_or_session_or_organization' }
    request_id { SecureRandom.hex(32) }
    session_hash { SecureRandom.hex(16) }
  end

  factory :session_view, parent: :view do
    association :viewable, factory: :immersive_session
  end

  factory :blog_post_view, parent: :view do
    association :viewable, factory: :blog_post_published
  end

  factory :recording_view, parent: :view do
    association :viewable, factory: :recording_published
  end

  factory :video_view, parent: :view do
    association :viewable, factory: :video_published
  end

  factory :user_view, parent: :view do
    association :viewable, factory: :user
  end

  factory :channel_view, parent: :view do
    association :viewable, factory: :channel
  end

  factory :guest_user_view, parent: :view do
    association :viewable, factory: :user
    user_id { nil }
  end

  factory :aa_stub_views, parent: :view
end
