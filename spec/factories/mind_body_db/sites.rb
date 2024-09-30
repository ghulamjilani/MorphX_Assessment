# frozen_string_literal: true
FactoryBot.define do
  factory :mind_body_db_site, class: 'MindBodyDb::Site' do
    organization { create(:organization) }
    remote_id { (0..9_999_999).to_a.sample }
    contact_email { |n| "mindbodyuser#{n}_#{rand(1..999_999)}@example.com" }
    country_code { %w[US DE FR ES IT].sample }
    currency_iso_code { %w[USD EUR].sample }
    description { Forgery(:lorem_ipsum).paragraphs(2) }
    logo_url { 'https://unite.live/assets/landing/logo.png' }
    name { "#{Forgery('name').company_name} #{Forgery('name').company_name}" }
    pricing_level { MindBodyDb::Site::PricingLevels::ALL.sample }
    time_zone { 'America/Los_Angeles' }
  end

  factory :aa_stub_mind_body_db_sites, parent: :mind_body_db_site
end
