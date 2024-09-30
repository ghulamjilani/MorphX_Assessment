# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}_#{rand(1..9999)}@example.com" }
    first_name { Forgery('name').first_name }
    last_name { Forgery('name').last_name }
    password { 'Abc123!' }
    gender { User::Genders::MALE }
    # public_display_name_source User::PublicDisplayNameSources::DISPLAY_NAME
    sequence(:authentication_token) { |n| "#{SecureRandom.hex}#{n}" }
    birthdate { 28.years.ago }
    password_confirmation { 'Abc123!' }
    confirmation_token { nil }
    confirmed_at { Time.zone.now }
    show_on_home { true }
    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
  end

  factory :stripe_user, parent: :user do
    after(:create) do |user|
      customer = Stripe::Customer.create(
        email: user.email,
        description: user.public_display_name
      )
      user.stripe_customer_id = customer.id
      user.save(validate: false)
    end
  end

  factory :stripe_user_with_card, parent: :stripe_user do
    after(:create) do |user|
      @stripe_test_helper = StripeMock.create_test_helper
      Stripe::Customer.create_source(user.stripe_customer_id, { source: @stripe_test_helper.generate_card_token })
    end
  end

  factory :user_with_presenter_account, parent: :user do
    after(:create) { |user| FactoryBot.create(:presenter_user_account, user: user) }
  end

  factory :user_with_participant_account, parent: :user do
    after(:create) { |user| FactoryBot.create(:participant_user_account, user: user) }
  end

  factory :user_with_credit_card, parent: :user_with_presenter_account do
    braintree_customer_id { SecureRandom.hex(6) }
  end

  factory :invited_user, parent: :user do
    invitation_token { SecureRandom.hex(20) }
    invitation_created_at { Time.zone.now }
    invitation_sent_at { Time.zone.now }
    invitation_accepted_at { nil }
    invitation_limit { nil }
    invited_by_id { FactoryBot.create(:user).id }
    invited_by_type { 'User' }

    after(:create) do |user|
      FactoryBot.create(:participant_user_account, user: user)
    end
  end

  factory :user_with_presenter_and_participant, parent: :user_with_presenter_account do
    after(:create) do |user|
      FactoryBot.create(:participant, user: user)
      FactoryBot.create(:presenter, user: user)
    end
  end

  factory :user_created_by_organization, parent: :user_with_presenter_account do
    parent_organization { FactoryBot.create(:organization) }
  end

  factory :presenter_user_created_by_organization, parent: :user_with_presenter_account do
    parent_organization { FactoryBot.create(:organization) }
    after(:create) do |user|
      FactoryBot.create(:organization_membership, user: user, organization: user.parent_organization, role: 'presenter')
    end
  end

  factory :manager_user_created_by_organization, parent: :user_with_presenter_account do
    parent_organization { FactoryBot.create(:organization) }
    after(:create) do |user|
      FactoryBot.create(:organization_membership, user: user, organization: user.parent_organization, role: 'manager')
    end
  end
  factory :administrator_user_created_by_organization, parent: :user_with_presenter_account do
    parent_organization { FactoryBot.create(:organization) }
    after(:create) do |user|
      FactoryBot.create(:organization_membership, user: user, organization: user.parent_organization,
                                                  role: 'administrator')
    end
  end

  factory :user_with_stripe_connect_account, parent: :user do
    after(:create) do |user|
      payout_method = FactoryBot.create(:payout_method, user: user)
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
          ssn_last_4: payout_identity.ssn_last_4,
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
      payout_method.update(pid: connect_account.id, is_default: true, status: :done)
      FactoryBot.create(:stripe_db_connect_account, user: user, account_id: connect_account.id)
    end
  end

  factory :user_without_confirmed_email, parent: :user do
    confirmation_token { Devise.token_generator.digest(User, :confirmation_token, 'abcdef') }
    confirmation_sent_at { 1.minute.ago }
    confirmed_at { nil }
  end

  factory :user_fake, parent: :user_with_presenter_account do
    fake { true }
  end

  factory :user_service_admin, parent: :user do
    platform_role { :service_admin }
  end

  factory :aa_stub_users, parent: :user
end
