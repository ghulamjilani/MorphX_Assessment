# frozen_string_literal: true

FactoryBot.define do
  factory :poll_vote, class: 'Poll::Vote' do
    association :user, factory: :user
    association :poll_option, factory: :poll_option
  end

  factory :aa_stub_poll_votes, parent: :poll_vote
end
