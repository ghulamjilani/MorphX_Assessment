# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::UsersController do
  render_views

  describe '.json request format' do
    describe 'POST create' do
      context 'when using email and password' do
        let(:password) { 'Az9!@#$' }
        let(:user) { create(:user, password: password, password_confirmation: password) }
        let(:params) do
          {
            email: user.email,
            password: password
          }
        end

        before do
          post :create, params: params, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:current_user)).not_to be_blank }
        it { expect(assigns(:auth_user_token)).not_to be_blank }
      end

      context 'when using email and organization token' do
        let(:organization_membership) { create(:organization_membership) }
        let(:organization) { organization_membership.organization }
        let(:params) { { email: user.email } }
        let(:auth_header_value) { "Bearer #{JwtAuth.organization(organization)}" }

        before do
          request.headers['Authorization'] = auth_header_value
          post :create, params: params, format: :json
        end

        context 'when user is organization owner' do
          let(:user) { organization.user }

          it { expect(response).to be_successful }
          it { expect(assigns(:current_user)).not_to be_blank }
          it { expect(assigns(:auth_user_token)).not_to be_blank }
        end

        context 'when user is organization member' do
          let(:user) { organization_membership.user }

          it { expect(response).to be_successful }
          it { expect(assigns(:current_user)).not_to be_blank }
          it { expect(assigns(:auth_user_token)).not_to be_blank }
        end
      end
    end

    describe 'DELETE destroy' do
      before do
        request.headers['Authorization'] = auth_header_value
        delete :destroy, format: :json
      end

      context 'when given user token' do
        let(:auth_user_token) { create(:auth_user_token) }
        let(:auth_header_value) do
          payload = { type: 'user', id: auth_user_token.user_id, tid: auth_user_token.id, exp: 1.day.from_now.to_i }
          "Bearer #{JWT.encode(payload, auth_user_token.jwt_secret)}"
        end

        it { expect(response).to be_successful }
      end
    end
  end
end
