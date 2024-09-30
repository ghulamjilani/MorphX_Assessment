# frozen_string_literal: true

FactoryBot.define do
  factory :activity, class: 'Log::Activity' do
    key { ['view'].sample }
    association :trackable,
                factory: %i[user organization listed_channel session_with_livestream_only_delivery video_published
                            recording_published].sample
    association :owner, factory: :user
    created_at { (0..240).to_a.sample.hours.ago }
    updated_at { created_at }
  end

  factory :view_activity, parent: :activity do
    key { 'view' }
  end

  factory :user_view_activity, parent: :view_activity do
    association :trackable, factory: :user
  end

  factory :organization_view_activity, parent: :view_activity do
    association :trackable, factory: :organization
  end

  factory :channel_view_activity, parent: :view_activity do
    association :trackable, factory: :listed_channel
  end

  factory :session_view_activity, parent: :view_activity do
    association :trackable, factory: :session_with_livestream_only_delivery
  end

  factory :video_view_activity, parent: :view_activity do
    association :trackable, factory: :video_published
  end

  factory :recording_view_activity, parent: :view_activity do
    association :trackable, factory: :recording_published
  end

  factory :aa_stub_log_activities, parent: :activity
end
