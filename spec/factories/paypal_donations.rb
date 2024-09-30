# frozen_string_literal: true
FactoryBot.define do
  factory :paypal_donation do
    payment_status { 'Pending' }
    payer_email { 'nfedyashev-buyer@gmail.com' }
    ipn_track_id { "cc3575d626d9b#{rand 9000}" }
    additional_data do
      { mc_gross: '20.99',
        protection_eligibility: 'Ineligible',
        address_status: 'confirmed',
        payer_id: 'UFNJKGZRSBAC8',
        tax: '0.00',
        address_street: '1+Main+St',
        payment_date: '13:25:44+Oct+13,+2015+PDT',
        payment_status: 'Pending',
        charset: 'windows-1252',
        address_zip: '95131',
        first_name: 'test',
        mc_fee: '0.33',
        address_country_code: 'US',
        address_name: 'test+buyer',
        notify_version: '3.8',
        custom: '',
        payer_status: 'verified',
        business: 'nfedyashev-facilitator@gmail.com',
        address_country: 'United+States',
        address_city: 'San+Jose',
        quantity: '0',
        verify_sign: 'ADvj-tIuMJxr3YEo-QPTwZC-2h.3AkEVqresFBoggpJR2C3t100V3tQD',
        payer_email: 'nfedyashev-buyer@gmail.com',
        txn_id: '6BK486076P3244908',
        payment_type: 'instant',
        last_name: 'buyer',
        address_state: 'CA',
        receiver_email: 'nfedyashev-facilitator@gmail.com',
        payment_fee: '0.33',
        receiver_id: 'GFU5LZSENTKRE',
        pending_reason: 'paymentreview',
        txn_type: 'web_accept',
        item_name: 'My+Donation',
        mc_currency: 'USD',
        item_number: '',
        residence_country: 'US',
        test_ipn: '1',
        transaction_subject: '',
        payment_gross: '20.99',
        ipn_track_id: 'cc3575d626d9b' }
    end
    user
    association :abstract_session, factory: :immersive_session
  end
end
