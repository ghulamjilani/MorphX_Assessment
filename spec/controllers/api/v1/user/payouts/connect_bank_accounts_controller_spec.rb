# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Payouts::ConnectBankAccountsController do
  let(:current_user) { create(:user) }
  let(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe 'POST :create' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method_with_stripe_connect_account, user: current_user) }
    let(:params) do
      {
        payout_method_id: payout_method.id,
        bank_account: {
          routing_number: '110000000',
          account_number: '000123456789',
          currency: 'USD',
          account_holder_name: current_user.full_name,
          account_holder_type: 'individual',
          country: 'US'
        }
      }
    end

    it 'does not fail' do
      post :create, xhr: true, params: params
      expect(response).to be_successful
    end
  end

  describe 'PUT :update' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method_with_stripe_connect_account_and_bank_account, user: current_user) }
    let(:params) do
      {
        id: payout_method.connect_account.bank_accounts.first.id,
        payout_method_id: payout_method.id,
        bank_account: {
          account_holder_name: current_user.full_name
        }
      }
    end

    it 'does not fail' do
      put :update, xhr: true, params: params
      expect(response).to be_successful
    end
  end
end
