# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::StudioRoomsController do
  let(:current_organization) { studio1.organization }
  let(:current_user) { current_organization.user }
  let(:studio1) { studio_room1.studio }
  let(:studio2) { create(:studio, organization: current_organization) }
  let(:studio_room1) { create(:studio_room) }
  let(:studio_room2) { create(:studio_room, studio: studio1) }
  let(:studio_room3) { create(:studio_room, studio: studio2) }
  let(:unaccessible_studio_room) { create(:studio_room) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        studio_room1
        studio_room2
        studio_room3
        unaccessible_studio_room
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
            expect(response.body).to include studio_room1.name
            expect(response.body).to include studio_room2.name
            expect(response.body).to include studio_room3.name
            expect(response.body).not_to include unaccessible_studio_room.name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(3)
          end
        end

        context 'when given studio_id params' do
          it 'does not fail and returns valid json' do
            get :index, params: { studio_id: studio1.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include studio_room1.name
            expect(response.body).to include studio_room2.name
            expect(response.body).not_to include studio_room3.name
            expect(response.body).not_to include unaccessible_studio_room.name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(2)
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(3)
            expect(response_body['pagination']['total_pages']).to eq(3)
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(3)
            expect(response_body['pagination']['total_pages']).to eq(3)
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end
      end
    end

    describe 'GET show:' do
      before do
        studio_room1
        studio_room2
        studio_room3
        unaccessible_studio_room
      end

      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: studio_room1.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when studio_room belongs to current organization' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: studio_room1.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include studio_room1.name
          end
        end

        context 'when studio_room does not belong to current organization' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: unaccessible_studio_room.id }, format: :json

            expect(response).to have_http_status :not_found
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).not_to include unaccessible_studio_room.name
          end
        end
      end
    end

    describe 'POST create:' do
      let(:valid_params) do
        {
          studio_id: studio1.id,
          studio_room: {
            name: "#{current_organization.name} Studio Room ##{rand(999)}",
            description: "Studio Room #{current_organization.description}"
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

        it 'creates new studio_room' do
          expect do
            post :create, params: valid_params, format: :json
            new_studio_room = StudioRoom.last
            expect(response).to be_successful
            expect(new_studio_room.studio_id).to eq valid_params[:studio_id]
            expect(new_studio_room.name).to eq valid_params[:studio_room][:name]
            expect(new_studio_room.description).to eq valid_params[:studio_room][:description]
          end.to change(StudioRoom, :count).by(1)
        end
      end
    end

    describe 'PUT update:' do
      let(:valid_params) do
        {
          id: studio_room1.id,
          studio_room: {
            name: "#{current_organization.name}  Room ##{rand(999)}",
            description: "Studio Room #{current_organization.description}"
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

        it 'updates studio_room' do
          put :update, params: valid_params, format: :json
          studio_room = StudioRoom.find(valid_params[:id])
          expect(response).to be_successful
          expect(studio_room.name).to eq valid_params[:studio_room][:name]
          expect(studio_room.description).to eq valid_params[:studio_room][:description]
        end
      end
    end

    describe 'DELETE destroy:' do
      let!(:studio_room4) { create(:studio_room, studio: studio1) }
      let(:valid_params) { { id: studio_room4.id } }

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

        it 'destroys studio_room' do
          delete :destroy, params: valid_params, format: :json
          studio_room = StudioRoom.find_by(id: valid_params[:id])
          expect(response).to be_successful
          expect(studio_room).to be nil
        end
      end
    end
  end
end
