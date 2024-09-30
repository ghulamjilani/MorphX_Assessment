# frozen_string_literal: true
FactoryBot.define do
  factory :poll, class: 'Poll::Poll' do
    question { Forgery(:lorem_ipsum).title(random: true) }
    association :poll_template, factory: :poll_template
    association :model, factory: :session
  end

  factory :aa_stub_polls, parent: :poll
end
