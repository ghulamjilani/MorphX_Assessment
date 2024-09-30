# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ChannelFreeSubscriptionsController do
  let(:current_user) { create(:stripe_user_with_card) }
  let!(:free_subscription) { create(:free_subscription, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when given id param' do
        before do
          get :show, params: { id: free_subscription.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
