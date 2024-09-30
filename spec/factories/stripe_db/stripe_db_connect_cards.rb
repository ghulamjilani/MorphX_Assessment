# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_connect_card, class: 'StripeDb::ConnectCard' do
    last4 { '4242' }
  end
end
