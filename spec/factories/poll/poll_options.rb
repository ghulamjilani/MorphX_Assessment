# frozen_string_literal: true

FactoryBot.define do
  factory :poll_option, class: 'Poll::Option' do
    title { Forgery(:lorem_ipsum).title(random: true) }
    association :poll, factory: :poll
  end

  factory :aa_stub_poll_options, parent: :poll_option
end
