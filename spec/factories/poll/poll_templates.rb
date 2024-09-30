# frozen_string_literal: true

FactoryBot.define do
  factory :poll_template, class: 'Poll::Template::Poll' do
    name { Forgery(:lorem_ipsum).title(random: true) }
    question { Forgery(:lorem_ipsum).title(random: true) }
    organization
    user
  end

  factory :aa_stub_poll_templates, parent: :poll_template
end
