# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Payouts::PayoutMethodsController do
  let(:current_user) { create(:user) }
  let(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe 'GET :index' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    it 'does not fail' do
      get :index, xhr: true
      expect(response).to be_successful
    end
  end

  describe 'GET :show' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail' do
      get :show, xhr: true, params: { id: payout_method.id }
      expect(response).to be_successful
    end
  end

  describe 'POST :create' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    it 'does not fail' do
      post :create, xhr: true, params: { payout_method: { business_type: 'individual', provider: 'stripe', country: 'US' } }
      expect(response).to be_successful
    end
  end

  describe 'PUT :update' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail when default updated' do
      put :update, xhr: true, params: { id: payout_method.id, default: true }
      expect(response).to be_successful
    end

    it 'fails when tos_acceptance updated without connect_account' do
      put :update, xhr: true, params: { id: payout_method.id, accept_tos: true }
      expect(response).not_to be_successful
    end
  end

  describe 'DELETE :destroy' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail' do
      delete :destroy, xhr: true, params: { id: payout_method.id }
      expect(response).to be_successful
    end
  end
end
