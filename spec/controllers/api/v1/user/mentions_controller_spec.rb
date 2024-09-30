# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::MentionsController do
  describe '.json request format' do
    let(:current_user) { create(:user) }
    let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      let(:params) { { query: current_user.slug.first(4) } }

      before do
        get :index, params: params, format: :json
      end

      render_views

      it { expect(response).to be_successful }
      it { expect(response.body).to include(current_user.slug) }
    end
  end
end
