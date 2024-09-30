# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ServiceSubscriptionsController do
  let(:current_user) { create(:stripe_user_with_card) }
  let!(:plan) { create(:service_plan_with_stripe_data) }
  let!(:service_subscription) do
    subscription = create(:stripe_service_subscription, user: current_user, stripe_plan: plan, status: 'trialing')
    subscription_attrs = {
      customer: current_user.stripe_customer_id,
      # default_tax_rates: [tax], # Skip For now because we don't have tax
      items: [{ plan: plan.stripe_id }]
    }
    stripe_subscription = Stripe::Subscription.create(subscription_attrs)
    subscription.stripe_id = stripe_subscription.id
    subscription.save
    subscription
  end
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        it { expect(response.body).to include plan.stripe_id.to_s }
      end
    end

    describe 'GET show:' do
      context 'when given id param' do
        before do
          get :show, params: { id: service_subscription.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include plan.stripe_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET current:' do
      context 'when given no params' do
        before do
          get :current, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include plan.stripe_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      context 'when given user with existing subscription' do
        before do
          post :create, params: { plan_id: plan.stripe_id,
                                  stripe_token: current_user.default_credit_card.id }, format: :json
        end

        it { expect(response).not_to be_successful }
        it { expect(response.body).to include 'You already have a subscription' }
      end

      context 'when given user with no subscription' do
        before do
          another_user = create(:stripe_user_with_card)
          request.headers['Authorization'] = "Bearer #{JwtAuth.user(another_user)}"
          post :create, params: { plan_id: plan.stripe_id,
                                  stripe_token: another_user.default_credit_card.id }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'PUT update:' do
      before do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
        allow(controller).to receive(:current_ability).and_return(@ability)
        allow(@ability).to receive(:authorize!).with(:edit_by_business_plan,
                                                     StripeDb::ServiceSubscription).and_return(true)
      end

      context 'cancel trial for trialing' do
        before do
          put :update, params: { id: service_subscription.id, cancel_trial: true }, format: :json
        end

        it { expect(response).to be_successful }
      end

      context 'cancel trial for active subscription' do
        before do
          another_user = create(:stripe_user_with_card)
          active_subscription = create(:stripe_service_subscription, user: another_user, stripe_plan: plan,
                                                                     status: 'active')

          subscription_attrs = {
            customer: another_user.stripe_customer_id,
            # default_tax_rates: [tax], # Skip For now because we don't have tax
            items: [{ plan: plan.stripe_id }]
          }
          stripe_subscription = Stripe::Subscription.create(subscription_attrs)
          active_subscription.stripe_id = stripe_subscription.id
          active_subscription.save

          request.headers['Authorization'] = "Bearer #{JwtAuth.user(another_user)}"
          put :update, params: { id: active_subscription.id, cancel_trial: true }, format: :json
        end

        it { expect(response).not_to be_successful }
        it { expect(response.body).to include I18n.t('controllers.api.v1.user.service_subscriptions.errors.subscription_not_trial') }
      end

      context 'change plan for active subscription' do
        let(:new_plan) { create(:service_plan_with_stripe_data) }

        before do
          another_user = create(:stripe_user_with_card)
          active_subscription = create(:stripe_service_subscription, user: another_user, stripe_plan: plan,
                                                                     status: 'active')

          subscription_attrs = {
            customer: another_user.stripe_customer_id,
            # default_tax_rates: [tax], # Skip For now because we don't have tax
            items: [{ plan: plan.stripe_id }]
          }
          stripe_subscription = Stripe::Subscription.create(subscription_attrs)
          active_subscription.stripe_id = stripe_subscription.id
          active_subscription.save

          request.headers['Authorization'] = "Bearer #{JwtAuth.user(another_user)}"
          put :update, params: { id: active_subscription.id, plan_id: new_plan.id }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'DELETE destroy:' do
      before do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
        allow(controller).to receive(:current_ability).and_return(@ability)
        allow(@ability).to receive(:authorize!).with(:edit_by_business_plan,
                                                     StripeDb::ServiceSubscription).and_return(true)
      end

      context 'cancel subscription' do
        before do
          delete :destroy, params: { id: service_subscription.id }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'POST pay:' do
      before do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
        allow(controller).to receive(:current_ability).and_return(@ability)
        allow(@ability).to receive(:authorize!).with(:edit_by_business_plan,
                                                     StripeDb::ServiceSubscription).and_return(true)
        stripe_item = double(Stripe::Subscription)
        latest_invoice = 'test'
        allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_item)
        allow(stripe_item).to receive(:latest_invoice).and_return(latest_invoice)
        allow(Stripe::Invoice).to receive(:pay).with(latest_invoice).and_return(true)
        allow(StripeDb::ServiceSubscription).to receive(:create_or_update_from_stripe).and_return(service_subscription)
      end

      context 'cancel subscription' do
        before do
          post :pay, params: { id: service_subscription.id }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end
  end
end
