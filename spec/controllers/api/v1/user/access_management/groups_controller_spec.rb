# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AccessManagement::GroupsController do
  let(:current_user) { create(:user) }
  let!(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    describe 'GET index:' do
      context 'when given no params' do
        let!(:credential_group) { create(:access_management_group) }

        render_views

        it 'does not fail and returns valid json' do
          get :index, params: {}, format: :json
          expect(response).to be_successful
          expect(response.body).to include credential_group.name
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'GET show:' do
      context 'when given no params' do
        let!(:credential_group) { create(:access_management_group) }

        render_views

        it 'does not fail and returns valid json' do
          get :show, params: { id: credential_group.id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include credential_group.name
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'POST create:' do
      context 'when given no params' do
        render_views

        it 'does not fail and returns valid json' do
          post :create, params: { group: { name: 'Custom role' } }, format: :json
          expect(response).to be_successful
          expect(response.body).to include 'Custom role'
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'DELETE destroy:' do
      context 'when given own role' do
        let(:credential_group) { create(:access_management_group, system: false, organization: organization) }

        render_views

        it 'does not fail and returns valid json' do
          delete :destroy, params: { id: credential_group.id }, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given system role' do
        let(:credential_group) { create(:access_management_group, system: true) }

        render_views

        it 'does not fail and returns valid json' do
          delete :destroy, params: { id: credential_group.id }, format: :json
          expect(response).not_to be_successful
        end
      end
    end
  end
end
