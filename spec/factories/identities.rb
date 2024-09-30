# frozen_string_literal: true
FactoryBot.define do
  factory :facebook_identity, class: 'Identity' do
    user
    sequence(:uid) { |n| "uid##{n}" }
    token { SecureRandom.hex }
    expires { true }
    expires_at { 1.year.from_now }
    provider { 'facebook' }
  end

  factory :zoom_identity, parent: :facebook_identity do
    provider { 'zoom' }
  end

  factory :aa_stub_identities, parent: :facebook_identity
end
