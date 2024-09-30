# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::UserTokensController do
  describe '.json request format' do
    let(:auth_user_token) { create(:auth_user_token) }
    let(:user) { auth_user_token.user }
    let(:auth_header_value) do
      payload = { type: 'refresh', id: user.id, tid: auth_user_token.id, exp: 1.day.from_now.to_i }
      "Bearer #{JWT.encode(payload, auth_user_token.jwt_secret)}"
    end

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET show' do
      before do
        get :show, format: :json
      end

      it { expect(response).to be_successful }
      it { expect(assigns(:current_user)).not_to be_blank }
      it { expect(assigns(:current_token).destroyed?).to be_truthy }
      it { expect(assigns(:auth_user_token)).not_to be_blank }
    end
  end
end
