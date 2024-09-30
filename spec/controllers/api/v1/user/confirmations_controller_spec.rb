# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ConfirmationsController do
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'POST create:' do
      context 'when user has unconfirmed email' do
        let(:current_user) { create(:user_without_confirmed_email) }

        it 'works' do
          request.headers['Authorization'] = auth_header_value
          post :create, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when user has confirmed email' do
        let(:current_user) { create(:user) }

        it 'returns 401' do
          request.headers['Authorization'] = auth_header_value
          post :create, format: :json
          expect(response).to have_http_status :unauthorized
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
