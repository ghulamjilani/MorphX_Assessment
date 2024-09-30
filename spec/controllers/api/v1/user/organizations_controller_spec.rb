# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::OrganizationsController do
  let(:user) { create(:organization).user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :index, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: 'current' }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: 'current' }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'PUT update:' do
      let(:request_params) do
        {
          id: 'current',
          organization: {
            name: 'test'
          }
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: request_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          put :update, params: request_params, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it 'updates user attributes' do
          expect(user.organization.reload.name).to eq 'test'
        end
      end
    end
  end
end
