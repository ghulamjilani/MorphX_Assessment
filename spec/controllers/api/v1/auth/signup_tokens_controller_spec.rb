# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::SignupTokensController do
  let(:signup_token) { create(:signup_token) }

  render_views

  describe '.json request format' do
    describe 'GET show' do
      let(:params) { { id: signup_token.token } }

      context 'when token exist and is valid' do
        before do
          get :show, params: params, format: :json
        end

        it { expect(response.status).to be 200 }

        it { expect(assigns(:signup_token)).not_to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end

      context 'when token does not exist' do
        let(:params) { { id: "_#{signup_token.token}" } }

        before do
          get :show, params: params, format: :json
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
          get :show, params: params, format: :json
        end

        it { expect(response.status).to be 404 }

        it { expect(assigns(:signup_token)).to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end

      context 'when token exist and is used' do
        let(:signup_token) { create(:signup_token, user: create(:user)) }

        before do
          get :show, params: params, format: :json
        end

        it { expect(response.status).to be 404 }

        it { expect(assigns(:signup_token)).to be_blank }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end
    end
  end
end
