# frozen_string_literal: true
FactoryBot.define do
  factory :link_preview do
    url { "https://#{Forgery(:internet).domain_name}/#{Forgery(:lorem_ipsum).words(3, random: true).split.map(&:parameterize).join('/')}" }
    image_url { "#{url}/logo.png" }
    title { Forgery(:lorem_ipsum).words(5, random: true) }
    description { Forgery(:lorem_ipsum).words(15, random: true) }
    status { LinkPreview::Statuses::DONE }
  end

  factory :link_preview_new, parent: :link_preview do
    image_url { nil }
    title { nil }
    description { nil }
    status { LinkPreview::Statuses::NEW }
  end

  factory :aa_stub_link_previews, parent: :link_preview
end
