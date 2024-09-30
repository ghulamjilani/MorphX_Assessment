# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ActivitiesController do
  let(:current_user) { create(:user) }
  let(:channel_view_activity) { create(:channel_view_activity, owner: current_user) }
  let!(:activities) do
    %w[user channel organization session video recording].map do |type|
      create("#{type}_view_activity".to_sym, owner: current_user)
    end.push(channel_view_activity)
  end
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

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
        end

        context 'when given no params' do
          it 'does not fail and returns valid json' do
            get :index, params: {}, format: :json

            expect(response).to be_successful
            expect(response.body).to include activities.first.id.to_s
            expect(response.body).to include activities.last.id.to_s
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(activities.size)
            expect(response_body['pagination']['total_pages']).to eq(activities.size)
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(activities.size)
            expect(response_body['pagination']['total_pages']).to eq(activities.size)
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end

        context 'when given trackable_type set to "Channel"' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { trackable_type: 'Channel' }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response.body).to include channel_view_activity.id.to_s
          end
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: channel_view_activity.id.to_s }, format: :json

          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        it 'does not fail and returns valid json' do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: channel_view_activity.id.to_s }, format: :json

          expect(response).to be_successful
          expect(response.body).to include channel_view_activity.id.to_s
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'DELETE destroy:' do
      let(:valid_params) { { id: [activities.first.id] } }

      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present and 1 ids' do
        it 'destroys activities' do
          request.headers['Authorization'] = auth_header_value
          delete :destroy, params: valid_params, format: :json
          expect(response).to be_successful
          all_activities = Log::Activity.where(:id.in => valid_params[:id])
          expect(all_activities.size).to eq(0)
        end
      end
    end

    describe 'GET destroy_all:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :destroy_all, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        it 'does not fail and returns valid json' do
          request.headers['Authorization'] = auth_header_value
          get :destroy_all, format: :json

          expect(response).to be_successful
          expect(Log::Activity.where(owner_id: current_user.id, owner_type: 'User').size).to eq(0)
        end
      end
    end
  end
end
