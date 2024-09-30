# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::OrganizationsController do
  describe '.json request format' do
    describe 'POST create' do
      let(:organization) { create(:organization, secret_key: SecureRandom.alphanumeric(8), secret_token: valid_token) }
      let(:valid_token) { 'abcdef' }
      let(:params) do
        {
          secret_key: secret_key,
          secret_token: secret_token
        }
      end

      before do
        post :create, params: params, format: :json
      end

      context 'when given valid secret_key and secret_token' do
        let(:secret_key) { organization.secret_key }
        let(:secret_token) { valid_token }

        it { expect(assigns(:organization)).not_to be_blank }
        it { expect(response).to be_successful }
      end

      context 'when given valid secret_key and invalid secret_token' do
        let(:secret_key) { organization.secret_key }
        let(:secret_token) { 'zdesbylvasya' }

        it { expect(assigns(:organization)).not_to be_blank }
        it { expect(response).not_to be_successful }
      end

      context 'when given invalid secret_key and valid secret_token' do
        let(:secret_key) { 'zdesbylvasya' }
        let(:secret_token) { valid_token }

        it { expect(assigns(:organization)).to be_blank }
        it { expect(response).not_to be_successful }
      end
    end
  end
end
