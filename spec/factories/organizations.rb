# frozen_string_literal: true
FactoryBot.define do
  factory :organization do
    user { create(:presenter).user }
    # industry
    name { "#{Forgery('name').company_name} #{Forgery('name').company_name}" }
    show_on_home { true }
    description { "description-#{Forgery(:lorem_ipsum).words(22)}" }
    tagline { "tagline-#{Forgery('lorem_ipsum').lorem_ipsum_characters[0..148]}" }
    website_url { "#{%w[http https].sample}://#{Forgery('internet').domain_name}" }
    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
  end

  factory :organization_with_subscription, parent: :organization do
    after(:build) do |organization|
      create(:stripe_service_subscription, user_id: organization.user_id)
    end
  end

  factory :organization_with_split_revenue_subscription, parent: :organization do
    split_revenue_plan { true }
  end

  factory :organization_fake, parent: :organization_with_subscription do
    fake { true }
    user { create(:presenter_fake).user }
  end

  factory :aa_stub_organizations, parent: :organization do
    after(:build) do |organization|
      create(:ffmpegservice_account_free_push, organization_id: organization.id, user_id: organization.user_id)
    end
  end
end
