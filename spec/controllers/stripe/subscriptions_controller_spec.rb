# frozen_string_literal: true

require 'spec_helper'

describe Stripe::SubscriptionsController do
  before do
    sign_in(current_user)
  end

  describe 'POST :create' do
    let(:current_user) { create(:user) }
    let!(:channel) { create(:channel) }
    let(:subscription) { create(:subscription, channel: channel, user: channel.organizer) }
    let(:plan) do
      build(:stripe_db_plan, amount: 9.99, interval_count: 1, interval: 'month', trial_period_days: 30,
                             channel_subscription: subscription)
    end
    let(:stripe_helper) { StripeMock.create_test_helper }

    before do
      @request.env['HTTP_REFERER'] = 'http://localhost:3000/'
      StripeMock.start

      product_stub = Hashie::Mash.new(
        id: "prod_123-#{channel.id}",
        name: channel.title,
        type: 'service'
      )
      allow(Stripe::Product).to receive(:create).and_return(product_stub)
      channel.create_stripe_product!

      plan_stub = Hashie::Mash.new(
        id: 'plan-classic-666',
        object: 'plan',
        active: true,
        aggregate_usage: nil,
        amount: plan.amount_cents,
        billing_scheme: 'per_unit',
        created: 1_556_550_759,
        currency: 'usd',
        interval: plan.interval,
        interval_count: plan.interval_count,
        livemode: false,
        metadata: {},
        nickname: nil,
        product: "prod_123-#{channel.id}",
        tiers_mode: nil,
        transform_usage: nil,
        trial_period_days: plan.trial_period_days,
        usage_type: 'licensed'
      )
      allow(Stripe::Plan).to receive(:create).and_return(plan_stub)
      allow(Stripe::Plan).to receive(:update).and_return(plan_stub)
      allow(Stripe::Plan).to receive(:retrieve).and_return(plan_stub)
      plan.save

      subscription_stub = Hashie::Mash.new(
        id: 'sub_8epEF0PuRhmltU',
        object: 'subscription',
        application_fee_percent: nil,
        billing: 'charge_automatically',
        billing_cycle_anchor: 1_466_202_990,
        billing_thresholds: nil,
        cancel_at: nil,
        cancel_at_period_end: false,
        canceled_at: 1_517_528_245,
        created: 1_466_202_990,
        current_period_end: 1_518_906_990,
        current_period_start: 1_516_228_590,
        customer: current_user.stripe_customer_id,
        days_until_due: nil,
        default_payment_method: nil,
        default_source: nil,
        default_tax_rates: [],
        discount: nil,
        ended_at: 1_517_528_245,
        items: {
          object: 'list',
          data: [
            {
              id: 'si_18NVZi2eZvKYlo2CUtBNGL9x',
              object: 'subscription_item',
              billing_thresholds: nil,
              created: 1_466_202_990,
              metadata: {},
              plan: {
                id: 'ivory-freelance-040',
                object: 'plan',
                active: true,
                aggregate_usage: nil,
                amount: 999,
                billing_scheme: 'per_unit',
                created: 1_466_202_980,
                currency: 'usd',
                interval: 'month',
                interval_count: 1,
                livemode: false,
                metadata: {},
                nickname: nil,
                product: 'prod_BUthVRQ7KdFfa7',
                tiers_mode: nil,
                transform_usage: nil,
                trial_period_days: nil,
                usage_type: 'licensed'
              },
              quantity: 1,
              subscription: 'sub_8epEF0PuRhmltU'
            }
          ],
          has_more: false,
          total_count: 1,
          url: '/v1/subscription_items?subscription=sub_8epEF0PuRhmltU'
        },
        latest_invoice: nil,
        livemode: false,
        metadata: {},
        plan: {
          id: 'ivory-freelance-040',
          object: 'plan',
          active: true,
          aggregate_usage: nil,
          amount: 999,
          billing_scheme: 'per_unit',
          created: 1_466_202_980,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          livemode: false,
          metadata: {},
          nickname: nil,
          product: 'prod_BUthVRQ7KdFfa7',
          tiers_mode: nil,
          transform_usage: nil,
          trial_period_days: nil,
          usage_type: 'licensed'
        },
        quantity: 1,
        schedule: nil,
        start: 1_466_202_990,
        status: 'active',
        # "tax_percent": nil,
        trial_end: nil,
        trial_start: nil
      )
      allow(Stripe::Subscription).to receive(:create).and_return(subscription_stub)
      allow(Stripe::Subscription).to receive(:retrieve).and_return(subscription_stub)
      allow(StripeDb::Plan).to receive(:create_or_update_from_stripe).and_return(plan)
    end

    after { StripeMock.stop }

    it 'subscribe to channel with trial first time' do
      post :create, params: { plan_id: plan.id }
      expect(flash[:error]).to be_blank
      expect(flash[:success]).to be_present
      expect(assigns(:trial_from_plan)).to eq(true)
      expect(response).to be_redirect
    end

    it 'not subscribe to channel if has active subscription' do
      post :create, params: { plan_id: plan.id }
      expect(flash[:error]).to be_blank
      post :create, params: { plan_id: plan.id }
      expect(flash[:error]).to eq("You've been already subscribed")
    end

    it 'subscribe to channel without trial second time' do
      post :create, params: { plan_id: plan.id }
      StripeDb::Subscription.where(user: current_user, stripe_plan: plan).update_all(status: 'cancelled')
      post :create, params: { plan_id: plan.id }
      expect(flash[:error]).to be_blank
      expect(assigns(:trial_from_plan)).to eq(false)
    end

    it 'subscribe to channel as gift without trial' do
      post :create, params: { plan_id: plan.id, gift: true, recipient: 'sub_recipient@example.com' }
      expect(flash[:error]).to be_blank
      expect(assigns(:trial_from_plan)).to eq(false)
    end

    it 'subscribe to channel as gift fails' do
      post :create, params: { plan_id: plan.id, gift: true }
      expect(flash[:error]).to be_present
    end
  end
end
