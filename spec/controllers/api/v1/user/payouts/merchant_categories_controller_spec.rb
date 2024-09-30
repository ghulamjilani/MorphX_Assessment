# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Payouts::MerchantCategoriesController do
  let(:current_user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe 'GET :index' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    it 'does not fail' do
      get :index, xhr: true
      expect(response).to be_successful
    end
  end
end
