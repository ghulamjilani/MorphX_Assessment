# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ChannelsController do
  let(:channel) { create(:listed_channel) }
  let(:current_user) { channel.organizer }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        request.headers['Authorization'] = auth_header_value
      end

      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given params' do
        let(:response_body) { JSON.parse(response.body) }

        before do
          get :index,
              params: { status: Channel::Statuses::APPROVED, limit: 1, offset: 1, order: 'asc', order_by: 'created_at' }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
