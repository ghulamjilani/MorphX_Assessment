# frozen_string_literal: true
FactoryBot.define do
  factory :payout_identity do
    payout_method
    first_name { payout_method.user.first_name }
    last_name { payout_method.user.last_name }
    date_of_birth { payout_method.user.birthdate }
    email { payout_method.user.email }
    ssn_last_4 { '8888' }
    phone { '16656545533' }
    address_line_1 { 'Line 1' }
    address_line_2 { nil }
    city { 'East Hanover' }
    state { 'NJ' }
    zip { '55555' }
  end
  factory :aa_stub_payout_identities, parent: :payout_identity
end
