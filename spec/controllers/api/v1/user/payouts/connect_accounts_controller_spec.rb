# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Payouts::ConnectAccountsController do
  let(:current_user) { create(:user) }
  let(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe 'POST :create' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    let(:payout_method) { create(:payout_method, user: current_user) }
    let(:params) do
      {
        payout_method_id: payout_method.id,
        account_info: {
          ssn_last_4: '0000', # rubocop:disable Naming/VariableNumber
          mcc: '5935',
          date_of_birth: '07/22/1990',
          phone: '+15556545454',
          business_website: Forgery('internet').domain_name,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          email: current_user.email,
          address_line_1: Forgery('address').street_address, # rubocop:disable Naming/VariableNumber
          address_line_2: nil, # rubocop:disable Naming/VariableNumber
          city: Forgery('address').city,
          state: Forgery('address').state_abbrev,
          zip: Forgery('address').zip,
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

    let(:payout_method) { create(:payout_method_with_stripe_connect_account, user: current_user) }
    let(:params) do
      {
        id: payout_method.connect_account.id,
        payout_method_id: payout_method.id,
        account_info: {
          ssn_last_4: '0000', # rubocop:disable Naming/VariableNumber
          mcc: '5935',
          date_of_birth: '07/22/1990',
          phone: '+15556545454',
          business_website: Forgery('internet').domain_name,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          email: current_user.email,
          address_line_1: Forgery('address').street_address, # rubocop:disable Naming/VariableNumber
          address_line_2: nil, # rubocop:disable Naming/VariableNumber
          city: Forgery('address').city,
          state: Forgery('address').state_abbrev,
          zip: Forgery('address').zip,
          country: 'US'
        }
      }
    end

    it 'does not fail' do
      put :update, xhr: true, params: params
      expect(response).to be_successful
    end
  end
end
