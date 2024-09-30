# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::WebsocketTokensController do
  let(:abstract_user) { create(:user) }
  let(:auth_header_value) { JwtAuth.user(abstract_user) }

  render_views

  describe 'POST create' do
    context 'when given no auth header' do
      before do
        post :create, params: { visitor_id: SecureRandom.uuid }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(assigns(:auth_websocket_token)).to be_present }
    end

    context 'when given user auth header' do
      before do
        request.headers['Authorization'] = auth_header_value
        post :create, params: { visitor_id: SecureRandom.uuid }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(assigns(:auth_websocket_token)).to be_present }
    end

    context 'when given guest auth header' do
      let(:abstract_user) { create(:guest) }
      let(:auth_header_value) { JwtAuth.guest(abstract_user) }

      before do
        request.headers['Authorization'] = auth_header_value
        post :create, params: { visitor_id: SecureRandom.uuid }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(assigns(:auth_websocket_token)).to be_present }
    end
  end
end
