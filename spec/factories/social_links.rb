# frozen_string_literal: true
FactoryBot.define do
  factory :social_link do
    association :entity, factory: :user_account
    sequence(:link) { |n| ["handle#{n}", "@handle#{n}"].sample } # has to handle both
    provider { [SocialLink::Providers::TWITTER, SocialLink::Providers::INSTAGRAM].sample }
  end

  factory :personal_social_link, class: 'SocialLink' do
    association :entity, factory: :user_account
    sequence(:link) { |n| "http://mydomain#{n}.local" }
    provider { SocialLink::Providers::EXPLICIT }
  end

  factory :corpoprate_social_link, class: 'SocialLink' do
    association :entity, factory: :organization
    sequence(:link) { |n| "http://mydomain#{n}.local" }
    provider { SocialLink::Providers::EXPLICIT }
  end

  factory :aa_stub_social_links, parent: :social_link
end
