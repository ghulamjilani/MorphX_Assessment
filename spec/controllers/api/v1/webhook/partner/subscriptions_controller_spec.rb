# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Webhook::Partner::SubscriptionsController do
  let(:user) { create(:user) }
  let(:partner_plan) { create(:partner_plan) }
  let(:organization) { partner_plan.organization }
  let(:customer_email) { Forgery(:internet).email_address }
  let(:auth_header_value) { "Bearer #{JwtAuth.organization_integration(organization)}" }

  render_views

  before do
    request.headers['Authorization'] = auth_header_value
  end

  describe 'POST create:' do
    let(:params) do
      {
        plan_id: partner_plan.foreign_plan_id,
        subscription_id: SecureRandom.uuid,
        status: 'completed',
        customer: {
          id: SecureRandom.uuid,
          email: customer_email,
          first_name: 'John',
          last_name: 'Doe'
        }
      }
    end

    context 'when customer is not registered yet' do
      it { expect { post :create, params: params, format: :json }.to not_raise_error.and change(FreeSubscription, :count).and change(User, :count) }
    end

    context 'when customer is already registered' do
      let(:customer_email) { user.email }

      it { expect { post :create, params: params, format: :json }.to not_raise_error.and change(user.free_subscriptions, :count) }
    end
  end
end
