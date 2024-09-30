# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::UserSearchController do
  let(:user) { create(:user) }
  let(:relevant_user1) { create(:user, email: 'vpupkin2@unite.live') }
  let(:relevant_user2) { create(:user, email: 'vpupkin@unite.live') }
  let(:irrelevant_user) { create(:user) }
  let(:response_body) { JSON.parse(response.body) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, params: { query: 'pupkin' }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          user
          relevant_user1
          relevant_user2
          irrelevant_user
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no query param' do
          context 'when given no other params' do
            it 'does not fail and returns valid json' do
              get :index, format: :json
              expect(response).to be_successful
              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response.body).to include(user.display_name)
              expect(response.body).to include(relevant_user1.display_name)
              expect(response.body).to include(relevant_user2.display_name)
              expect(response.body).to include(irrelevant_user.display_name)
            end
          end

          context 'when given limit param' do
            context 'when given no offset param' do
              it 'does not fail and returns valid json' do
                get :index, params: { limit: 1 }, format: :json
                expect(response).to be_successful
                expect { JSON.parse(response.body) }.not_to raise_error, response.body
                expect(response_body['pagination']['count']).to eq(4)
                expect(response_body['pagination']['current_page']).to eq(1)
                expect(response_body['pagination']['total_pages']).to eq(4)
              end
            end

            context 'when given offset param' do
              it 'does not fail and returns valid json' do
                get :index, params: { limit: 1, offset: 2 }, format: :json
                expect(response).to be_successful
                expect { JSON.parse(response.body) }.not_to raise_error, response.body
                expect(response_body['pagination']['count']).to eq(4)
                expect(response_body['pagination']['current_page']).to eq(3)
                expect(response_body['pagination']['total_pages']).to eq(4)
              end
            end
          end
        end

        context 'when given query param' do
          context 'when given limit param' do
            context 'when given no offset param' do
              it 'does not fail and returns valid json' do
                get :index, params: { query: 'pupkin', order_by: 'created_at', limit: 1 }, format: :json
                expect(response).to be_successful
                expect { JSON.parse(response.body) }.not_to raise_error, response.body
                expect(response_body['pagination']['count']).to eq(2)
                expect(response_body['pagination']['current_page']).to eq(1)
                expect(response_body['pagination']['total_pages']).to eq(2)
                expect(response.body).to include(relevant_user1.display_name)
                expect(response.body).not_to include(relevant_user2.display_name)
                expect(response.body).not_to include(user.display_name)
                expect(response.body).not_to include(irrelevant_user.display_name)
              end
            end

            context 'when given offset param' do
              it 'does not fail and returns valid json' do
                get :index, params: { query: 'pupkin', order_by: 'created_at', limit: 1, offset: 1 }, format: :json
                expect(response).to be_successful
                expect { JSON.parse(response.body) }.not_to raise_error, response.body
                expect(response_body['pagination']['count']).to eq(2)
                expect(response_body['pagination']['current_page']).to eq(2)
                expect(response_body['pagination']['total_pages']).to eq(2)
                expect(response.body).to include(relevant_user2.display_name)
                expect(response.body).not_to include(relevant_user1.display_name)
                expect(response.body).not_to include(user.display_name)
                expect(response.body).not_to include(irrelevant_user.display_name)
              end
            end
          end
        end
      end
    end
  end
end
