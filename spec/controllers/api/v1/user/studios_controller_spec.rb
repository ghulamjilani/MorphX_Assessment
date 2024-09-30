# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::StudiosController do
  let(:current_organization) { create(:organization) }
  let(:current_user) { current_organization.user }
  let(:organization2) { create(:organization) }
  let(:studio1) { create(:studio, organization: current_organization) }
  let(:studio2) { create(:studio, organization: current_organization) }
  let(:studio3) { create(:studio, organization: organization2) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        studio1
        studio2
        studio3
      end

      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          it 'does not fail and returns valid json' do
            get :index, params: {}, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include studio1.name
            expect(response.body).to include studio2.name
            expect(response.body).not_to include studio3.name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(2)
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response_body['pagination']['total_pages']).to eq(2)
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response_body['pagination']['total_pages']).to eq(2)
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end
      end
    end

    describe 'GET show:' do
      before do
        studio1
        studio2
        studio3
      end

      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: studio1.id }, format: :json

          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when studio belongs to current organization' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: studio1.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include studio1.name
          end
        end

        context 'when studio does not belong to current organization' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: studio3.id }, format: :json

            expect(response).to have_http_status :not_found
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).not_to include studio3.name
          end
        end
      end
    end

    describe 'POST create:' do
      let(:valid_params) do
        {
          studio: {
            name: "#{current_organization.name} Studio ##{rand(999)}",
            description: "Studio #{current_organization.description}",
            phone: '55555555',
            address: 'Metallurgiv 2, Zaporizhzhya, 69000, Ukraine'
          }
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          post :create, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'creates new studio' do
          expect do
            post :create, params: valid_params, format: :json
            new_studio = Studio.last
            expect(response).to be_successful
            expect(new_studio.name).to eq valid_params[:studio][:name]
            expect(new_studio.organization_id).to eq current_organization.id
          end.to change(Studio, :count).by(1)
        end
      end
    end

    describe 'PUT update:' do
      let(:valid_params) do
        {
          id: studio1.id,
          studio: {
            name: "#{current_organization.name} Studio ##{rand(999)}",
            description: "Studio #{current_organization.description}",
            phone: '8888888',
            address: 'Metallurgiv 2, Zaporizhzhya, 69000, Ukraine'
          }
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'updates studio' do
          put :update, params: valid_params, format: :json
          studio = Studio.find(valid_params[:id])
          expect(response).to be_successful
          expect(studio.name).to eq valid_params[:studio][:name]
          expect(studio.description).to eq valid_params[:studio][:description]
          expect(studio.phone).to eq valid_params[:studio][:phone]
          expect(studio.address).to eq valid_params[:studio][:address]
        end
      end
    end

    describe 'DELETE destroy:' do
      let!(:studio4) { create(:studio, organization: current_organization) }
      let(:valid_params) { { id: studio4.id } }

      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'destroys studio' do
          delete :destroy, params: valid_params, format: :json
          studio = Studio.find_by(id: valid_params[:id])
          expect(response).to be_successful
          expect(studio).to be nil
        end
      end
    end
  end
end
