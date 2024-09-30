# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::MarketingTools::OptInModalsController do
  let(:channel) { create(:approved_channel) }
  let(:current_user) { channel.organizer }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views
  describe '.json request format' do
    describe 'GET index:' do
      let(:mops) { create(:opt_in_modal, channel: channel) }

      context 'when JWT missing' do
        it 'returns 401' do
          mops
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        before do
          mops
          request.headers['Authorization'] = auth_header_value
        end

        it 'returns 401' do
          get :index, format: :json

          expect(response).to have_http_status :forbidden
        end
      end

      context 'when JWT present' do
        before do
          mops
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          before do
            get :index, params: {}, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given order, order_by, limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          before do
            get :index, params: { order_by: 'created_at', order: 'asc', limit: 1, offset: 1 }, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end
  end
end
