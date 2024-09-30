# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::VideosController do
  let(:video) { create(:video_published) }
  let(:video2) { create(:video_published) }

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

      context 'when channel_id filter is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { channel_id: video.channel.id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include video.title
          expect(response.body).not_to include video2.title
        end
      end

      context 'when user_id filter is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { user_id: video.user_id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include video.title
          expect(response.body).not_to include video2.title
        end
      end

      context 'when room_id filter is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { room_id: video.room_id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include video.title
          expect(response.body).not_to include video2.title
        end
      end

      context 'when session_id filter is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { session_id: video.session.id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include video.title
          expect(response.body).not_to include video2.title
        end
      end

      context 'when limit param is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { limit: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['response']['videos'].size).to eq(1)
          expect(JSON.parse(response.body)['pagination']['limit']).to eq 1
        end
      end

      context 'when offset param is set' do
        it 'does not fail and returns valid json' do
          video
          video2
          get :index, params: { limit: 1, offset: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['pagination']['current_page']).to eq 2
        end
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: video.id }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end
  end
end
