# frozen_string_literal: true
FactoryBot.define do
  factory :payout_method do
    association :user, factory: :user
    business_type { 'individual' }
    country { 'US' }
    is_default { true }
    provider { 'stripe' }
    status { 'draft' }
  end

  factory :aa_stub_payout_methods, parent: :payout_method

  factory :payout_method_with_stripe_connect_account, parent: :payout_method do
    after(:create) do |payout_method|
      payout_identity = FactoryBot.create(:payout_identity, payout_method: payout_method)
      connect_account = Stripe::Account.create(
        type: 'custom',
        country: 'US',
        email: payout_identity.email,
        business_type: 'individual',
        requested_capabilities: ['transfers'],
        business_profile: {
          url: payout_identity.business_website
        },
        individual: {
          first_name: payout_identity.first_name,
          last_name: payout_identity.last_name,
          dob: {
            day: payout_identity.date_of_birth.day,
            month: payout_identity.date_of_birth.month,
            year: payout_identity.date_of_birth.year
          },
          email: payout_identity.email,
          ssn_last_4: payout_identity.ssn_last_4, # rubocop:disable Naming/VariableNumber
          phone: payout_identity.phone,
          address: {
            line1: payout_identity.address_line_1,
            line2: payout_identity.address_line_2,
            city: payout_identity.city,
            state: payout_identity.state,
            postal_code: payout_identity.zip,
            country: payout_identity.payout_method.country
          }
        },
        # Terms of service acceptance
        tos_acceptance: {
          date: Time.now.to_i,
          ip: '127.0.0.1',
          user_agent: 'unite.test/666'
        }
      )
      payout_method.update(pid: connect_account.id, is_default: true, status: :draft)
      FactoryBot.create(:stripe_db_connect_account, user: payout_method.user, account_id: connect_account.id)
    end
  end

  factory :payout_method_with_stripe_connect_account_and_bank_account, parent: :payout_method_with_stripe_connect_account do
    after(:create) do |payout_method|
      @stripe_test_helper = StripeMock.create_test_helper
      stripe_bank_account = Stripe::Account.create_external_account(
        payout_method.connect_account.account_id,
        { external_account: @stripe_test_helper.generate_bank_token }
      )
      FactoryBot.create(:stripe_db_connect_bank_account, stripe_id: stripe_bank_account.id, stripe_account_id: payout_method.connect_account.account_id)
    end
  end
end
