# frozen_string_literal: true

FactoryBot.define do
  factory :shortener_shortened_url, class: 'Shortener::ShortenedUrl' do
    association :owner, factory: :user
    url { 'http://test.cm' }
  end

  factory :aa_stub_shortener_shortened_urls, parent: :shortener_shortened_url
end
