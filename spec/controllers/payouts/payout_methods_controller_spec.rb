# frozen_string_literal: true

require 'spec_helper'

describe Payouts::PayoutMethodsController do
  describe 'GET :index' do
    before do
      sign_in current_user, scope: :user
      current_user.update(current_organization_id: organization.id)
    end

    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }

    it 'does not fail' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST :create' do
    before do
      sign_in current_user, scope: :user
      current_user.update(current_organization_id: organization.id)
    end

    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }

    it 'does not fail' do
      post :create, xhr: true, params: { account: { business_type: 'individual', provider: 'stripe', country: 'US' } }
      expect(response).to be_successful
    end
  end

  describe 'GET :edit' do
    before do
      sign_in current_user, scope: :user
      current_user.update(current_organization_id: organization.id)
    end

    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }
    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail' do
      get :edit, params: { id: payout_method.id }
      expect(response).to be_successful
    end
  end

  describe 'PUT :update' do
    before do
      sign_in current_user, scope: :user
      current_user.update(current_organization_id: organization.id)
    end

    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }
    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail' do
      put :update, params: { id: payout_method.id, primary: '1', accept_tos: '1' }
      expect(response).to redirect_to(payouts_payout_methods_url)
    end
  end

  describe 'DELETE :destroy' do
    before do
      sign_in current_user, scope: :user
      current_user.update(current_organization_id: organization.id)
    end

    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }
    let(:payout_method) { create(:payout_method, user: current_user) }

    it 'does not fail' do
      delete :destroy, params: { id: payout_method.id }
      expect(response).to redirect_to(payouts_payout_methods_url)
    end
  end
end
