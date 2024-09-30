# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AccessManagement::CredentialsController do
  let(:current_user) { create(:user) }
  let!(:credential) { create(:access_management_credential) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        render_views

        it 'does not fail and returns valid json' do
          get :index, params: {}, format: :json
          expect(response).to be_successful
          expect(response.body).to include credential.name
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
