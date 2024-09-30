# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Organization::UsersController do
  let(:user) { create(:user_with_presenter_account) }
  let(:child_user) { create(:presenter_user_created_by_organization, first_name: 'uniquename1') }
  let(:child_user1) do
    create(:administrator_user_created_by_organization, first_name: 'uniquename2',
                                                        parent_organization: current_organization)
  end
  let(:child_user2) do
    create(:manager_user_created_by_organization, first_name: 'uniquename3', parent_organization: current_organization)
  end
  let(:current_organization) { create(:organization) }
  let(:auth_header_value) { "Bearer #{JwtAuth.organization(current_organization)}" }

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

        context 'when given no organization_id param' do
          context 'with no params' do
            it 'does not fail and returns valid json' do
              child_user
              child_user1
              child_user2
              get :index, params: {}, format: :json

              expect(response).to be_successful
              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response.body).not_to include child_user.public_display_name
              expect(response.body).to include child_user1.public_display_name
              expect(response.body).to include child_user2.public_display_name
              expect(JSON.parse(response.body)['pagination']['count']).to eq(2)
            end
          end

          context 'when given limit param' do
            let(:response_body) { JSON.parse(response.body) }

            it 'does not fail and returns valid json' do
              child_user
              child_user1
              child_user2
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
              child_user
              child_user1
              child_user2
              get :index, params: { limit: 1, offset: 1 }, format: :json

              expect(response).to be_successful
              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response_body['pagination']['count']).to eq(2)
              expect(response_body['pagination']['total_pages']).to eq(2)
              expect(response_body['pagination']['current_page']).to eq(2)
            end
          end
        end

        context 'when given organization_id param' do
          it 'does not fail and returns valid json' do
            child_user
            child_user1
            child_user2
            get :index, params: { organization_id: child_user.parent_organization_id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include child_user.public_display_name
            expect(response.body).not_to include child_user1.public_display_name
            expect(response.body).not_to include child_user2.public_display_name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(1)
          end
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: user.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when user exists' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: user.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end
    end

    describe 'POST create:' do
      let(:valid_params) do
        {
          user: {
            first_name: Forgery('name').first_name,
            last_name: Forgery('name').last_name,
            email: "user#{rand 0..999}@example.com",
            password: 'Abcdef123!',
            gender: [User::Genders::MALE, User::Genders::FEMALE].sample,
            birthdate: 30.years.ago
          },
          organization_membership: {
            role: %w[administrator manager presenter].sample
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

        it 'creates new user' do
          expect do
            post :create, params: valid_params, format: :json
            new_user = User.last

            expect(new_user.first_name).to eq valid_params[:user][:first_name]
            expect(new_user.parent_organization_id).to eq current_organization.id
          end.to change(User, :count).by(1)
        end

        it 'creates organization membership' do
          expect do
            post :create, params: valid_params, format: :json
            om = OrganizationMembership.last
            expect(om.organization).to eq current_organization
            expect(om.user.first_name).to eq valid_params[:user][:first_name]
            expect(om.role).to eq valid_params[:organization_membership][:role]
          end.to change(OrganizationMembership, :count).by(1)
        end
      end
    end
  end
end
