# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::PageBuilder::SystemTemplatesController do
  let(:current_user) { create(:user, platform_role: :platform_owner) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:system_template) { create(:pb_system_template) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      let(:system_template) { create(:pb_system_template) }

      context 'when JWT missing' do
        it 'returns 401' do
          system_template
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        before do
          system_template
          request.headers['Authorization'] = auth_header_value
        end

        it 'returns 401' do
          get :index, format: :json

          expect(response).to have_http_status :forbidden
        end
      end

      context 'when JWT present' do
        before do
          system_template
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          before do
            get :index, params: {}, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given order, order_by, limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          before do
            get :index, params: { order_by: 'created_at', order: 'asc', limit: 1, offset: 1 }, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: system_template.id, name: system_template.name }, format: :json

          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: system_template.id, name: system_template.name }, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include system_template.name }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      let(:template_name) { Forgery(:name).full_name.parameterize.underscore }

      context 'when JWT missing' do
        it 'returns 401' do
          post :create, params: { name: template_name, body: {}.to_json }, format: :json

          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when given random user missing' do
        let(:current_user) { create(:user) }

        it 'returns 403' do
          request.headers['Authorization'] = auth_header_value
          post :create, params: { name: template_name, body: {}.to_json }, format: :json

          expect(response).to have_http_status :forbidden
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          post :create, params: { name: template_name, body: {}.to_json }, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include template_name }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'DELETE destroy:' do
      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: { id: system_template.id, name: system_template.name }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present and 1 ids' do
        it 'destroys activities' do
          request.headers['Authorization'] = auth_header_value
          delete :destroy, params: { id: system_template.id, name: system_template.name }, format: :json
          expect(response).to be_successful
        end
      end
    end
  end
end
