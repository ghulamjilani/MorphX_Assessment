# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::StreamPreviewsController do
  let(:organization) { create(:organization) }
  let(:ffmpegservice_account) { create(:ffmpegservice_account, organization: organization) }
  let(:current_user) { ffmpegservice_account.organization.user }
  let!(:stream_preview) do
    create(:stream_preview, ffmpegservice_account: ffmpegservice_account, organization: organization, user: current_user)
  end
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

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
        context 'when returns correct json' do
          before do
            request.headers['Authorization'] = auth_header_value
            get :index, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'GET show:' do
      context 'when returns stream preview' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: stream_preview.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        it { expect(response.body).to include stream_preview.id.to_s }
      end
    end

    describe 'DELETE destroy:' do
      context 'when stops stream preview' do
        before do
          request.headers['Authorization'] = auth_header_value
          delete :destroy, params: { id: stream_preview.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        it { expect(response.body).to include stream_preview.id.to_s }
      end
    end
  end
end
