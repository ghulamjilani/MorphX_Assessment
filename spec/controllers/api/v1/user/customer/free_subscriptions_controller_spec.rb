# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Customer::FreeSubscriptionsController do
  let(:free_subscription) { create(:free_subscription) }
  let(:current_user) { free_subscription.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  before do
    request.headers['Authorization'] = auth_header_value
  end

  describe 'GET index:' do
    let(:params) do
      {
        order_by: %w[created_at start_at end_at].sample,
        order: %w[asc desc].sample,
        limit: 1,
        offset: 0
      }
    end

    before do
      get :index, params: params, format: :json
    end

    it { expect(response).to be_successful }

    it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
  end
end
