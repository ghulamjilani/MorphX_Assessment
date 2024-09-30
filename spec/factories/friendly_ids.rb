# frozen_string_literal: true

FactoryBot.define do
  factory :friendly_id_slug, class: 'FriendlyId::Slug' do
    association :sluggable, factory: :immersive_session
    sequence(:slug) { |n| "name-#{n}" }
  end
  factory :aa_stub_friendly_id_slugs, parent: :friendly_id_slug
end
