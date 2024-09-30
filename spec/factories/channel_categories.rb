# frozen_string_literal: true
FactoryBot.define do
  factory :channel_category do
    sequence(:name) { |n| "synthetic-name-#{n} #{Forgery::Name.industry}" }
    description_in_markdown_format { 'Lorem ipsum' }
  end

  factory :aa_stub_channel_categories, parent: :channel_category
end
