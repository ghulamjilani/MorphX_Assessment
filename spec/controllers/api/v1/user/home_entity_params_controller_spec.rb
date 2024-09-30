# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::HomeEntityParamsController do
  let(:current_user) { create(:user, platform_role: 'platform_owner') }
  let(:another_user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:auth_header_value2) { "Bearer #{JwtAuth.user(another_user)}" }
  let(:model) { create(:session) }

  render_views

  describe '.json request format' do
    describe 'POST hide_on_home:' do
      context 'when JWT missing' do
        it 'returns 401' do
          post :hide_on_home, params: { model_id: model.id, model_type: 'Session', hide_on_home: true }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when platform_role not platform_owner' do
        before do
          request.headers['Authorization'] = auth_header_value2
        end

        it 'returns 401' do
          post :hide_on_home, params: { model_id: model.id, model_type: 'Session', hide_on_home: true }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          post :hide_on_home, params: { model_id: model.id, model_type: 'Session', hide_on_home: true }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'POST set_weight:' do
      context 'when JWT missing' do
        it 'returns 401' do
          post :set_weight, params: { model_id: model.id, model_type: 'Session', promo_weight: 20 }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when platform_role not platform_owner' do
        before do
          request.headers['Authorization'] = auth_header_value2
        end

        it 'returns 401' do
          post :set_weight, params: { model_id: model.id, model_type: 'Session', promo_weight: 20 }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          post :set_weight, params: { model_id: model.id, model_type: 'Session', promo_weight: 20 }, format: :json
        end

        it { expect(response).to be_successful }
      end
    end
  end
end
