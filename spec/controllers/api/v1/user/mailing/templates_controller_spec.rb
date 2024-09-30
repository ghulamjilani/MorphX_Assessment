# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Mailing::TemplatesController do
  describe '.json request format' do
    let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

    render_views

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      let(:current_user) { create(:user) }

      before do
        get :index, format: :json
      end
    end
  end
end
