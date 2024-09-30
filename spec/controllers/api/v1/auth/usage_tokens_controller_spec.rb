# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::UsageTokensController do
  describe '.json request format' do
    let(:user) { create(:user) }
    let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }
    let(:visitor_id) { SecureRandom.uuid }

    render_views

    before do
      Rails.application.credentials.global[:usage][:user_messages_url] = 'test'
      request.headers['Authorization'] = auth_header_value
    end

    describe 'POST create' do
      context 'when visitor_id set in cookie' do
        before do
          cookies[:visitor_id] = visitor_id
          post :create, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error }

        it { expect(assigns(:usage_jwt)).to be_present }
      end

      context 'when visitor_id set in params' do
        let(:params) { { visitor_id: visitor_id } }

        before do
          post :create, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error }

        it { expect(assigns(:usage_jwt)).to be_present }
      end
    end
  end
end
