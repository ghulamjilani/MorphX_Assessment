# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::SystemThemesController do
  let!(:system_themes) { create_list(:system_theme, 3) }
  let(:current_user) { create(:user, can_use_debug_area: true) }
  let(:another_user) { create(:user, can_use_debug_area: false) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:auth_header_value2) { "Bearer #{JwtAuth.user(another_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when can_use_debug_area False' do
        before do
          request.headers['Authorization'] = auth_header_value2
        end

        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'returns system themes' do
          before do
            request.headers['Authorization'] = auth_header_value
            get :index, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: system_themes.sample.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when can_use_debug_area False' do
        before do
          request.headers['Authorization'] = auth_header_value2
        end

        it 'returns 401' do
          get :show, params: { id: system_themes.sample.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'returns system themes' do
          before do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: system_themes.sample.id }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'PUT update:' do
      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: { id: system_themes.sample.id, theme: { name: 'new name' } }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when can_use_debug_area False' do
        before do
          request.headers['Authorization'] = auth_header_value2
        end

        it 'returns 401' do
          put :update, params: { id: system_themes.sample.id, theme: { name: 'new name' } }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'returns system themes' do
          before do
            theme = system_themes.sample
            request.headers['Authorization'] = auth_header_value
            put :update, params: { id: theme.id, theme: { name: 'new name' } }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
          it { expect { theme.name.to eq 'new name' } }
        end
      end
    end
  end
end
