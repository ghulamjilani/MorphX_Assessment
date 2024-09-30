# frozen_string_literal: true
FactoryBot.define do
  factory :organizational_channel_presentership do
    presenter
    association :channel, factory: :listed_channel
  end
end
