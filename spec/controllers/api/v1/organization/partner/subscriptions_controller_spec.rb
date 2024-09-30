# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Organization::Partner::SubscriptionsController do
  let(:partner_subscription) { create(:partner_subscription) }
  let(:organization) { partner_subscription.organization }
  let(:auth_header_value) { JwtAuth.organization(organization) }

  render_views

  before do
    request.headers['Authorization'] = auth_header_value
  end

  describe 'GET :index' do
    let(:params) do
      {
        foreign_subscription_id: partner_subscription.foreign_subscription_id,
        partner_plan_id: partner_subscription.partner_plan_id,
        free_subscription_id: partner_subscription.free_subscription_id,
        foreign_customer_email: partner_subscription.foreign_customer_email
      }
    end

    before do
      get :index, params: params, format: :json
    end

    it { expect(response).to be_successful }

    it { expect(assigns(:current_organization)).not_to be_blank }

    it { expect(assigns(:partner_subscriptions)).not_to be_blank }
  end
end
