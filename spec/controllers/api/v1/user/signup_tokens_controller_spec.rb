# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::SignupTokensController do
  let(:signup_token) { create(:signup_token) }
  let(:current_user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'POST create' do
      let(:params) do
        {
          id: 'token',
          signup_token: {
            token: signup_token.token
          }
        }
      end

      before do
        request.headers['Authorization'] = auth_header_value
      end

      context 'when token exist and is valid' do
        before do
          post :create, params: params, format: :json
        end

        it { expect(response.status).to be 200 }

        it { expect(assigns(:signup_token)).not_to be_blank }

        it { expect(assigns(:current_user).can_use_wizard).to eq(signup_token.can_use_wizard) }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end

      context 'when token does not exist' do
        let(:params) { { id: 'token', signup_token: { token: "_#{signup_token.token}" } } }

        before do
          post :create, params: params, format: :json
        end

        it { expect(response.status).to be 404 }

        it { expect(assigns(:signup_token)).to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end

      context 'when token exist and is expired' do
        let(:signup_token) do
          model = create(:signup_token)
          model.update_column(:created_at, (SignupToken.lifetime_days + 1).days.ago)
          model
        end

        before do
          post :create, params: params, format: :json
        end

        it { expect(response.status).to be 404 }

        it { expect(assigns(:signup_token)).to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end

      context 'when token exist and is used' do
        let(:signup_token) { create(:signup_token, user: create(:user)) }

        before do
          post :create, params: params, format: :json
        end

        it { expect(response.status).to be 404 }

        it { expect(assigns(:signup_token)).to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end
    end
  end
end
