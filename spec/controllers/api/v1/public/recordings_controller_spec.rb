# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::RecordingsController do
  let(:recording) { create(:recording_published) }
  let(:recording2) { create(:recording_published, title: "random title#{rand(999)}") }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when no params present' do
        it 'does not fail and returns valid json' do
          get :index, format: :json

          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when channel filter is set' do
        it 'does not fail and returns valid json' do
          get :index, params: { channel_id: recording.channel_id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include recording.title
          expect(response.body).not_to include recording2.title
        end
      end

      context 'when organization filter is set' do
        it 'does not fail and returns valid json' do
          get :index, params: { organization_id: recording.channel.organization_id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include recording.title
          expect(response.body).not_to include recording2.title
        end
      end

      context 'when limit param is set' do
        it 'does not fail and returns valid json' do
          recording
          recording2
          get :index, params: { limit: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['response']['recordings'].size).to eq(1)
          expect(JSON.parse(response.body)['pagination']['limit']).to eq 1
        end
      end

      context 'when offset param is set' do
        it 'does not fail and returns valid json' do
          recording
          recording2
          get :index, params: { limit: 1, offset: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['pagination']['current_page']).to eq 2
        end
      end

      context 'when given created_at params' do
        before do
          get :index, params: params, format: :json
        end

        context 'when given only created_at_from param' do
          let(:params) { { created_at_from: (recording.created_at - 1.hour).utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
        end

        context 'when given only created_at_to param' do
          let(:params) { { created_at_to: (recording.created_at + 1.hour).utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
        end

        context 'when given both created_at_from and created_at_to params' do
          let(:params) do
            {
              created_at_from: (recording.created_at + 1.hour).utc.to_fs(:rfc3339),
              created_at_to: (recording.created_at + 1.hour).utc.to_fs(:rfc3339)
            }
          end

          it { expect(response).to be_successful }
        end
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: recording.id }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end
  end
end
