# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::VideosController do
  let(:video) { create(:video_published, title: Forgery(:lorem_ipsum).words(3, random: true)) }
  let(:video2) { create(:video_published, title: Forgery(:lorem_ipsum).words(3, random: true)) }
  let(:current_user) { video.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      before do
        get :index, params: params, format: :json
      end

      context 'when no params set' do
        let(:params) { {} }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include video.title }

        it { expect(response.body).not_to include video2.title }
      end

      context 'when channel_id filter is set' do
        let(:params) { { channel_id: video.channel.id } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include video.title }

        it { expect(response.body).not_to include video2.title }
      end

      context 'when room_id filter is set' do
        let(:params) { { room_id: video.room_id } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include video.title }

        it { expect(response.body).not_to include video2.title }
      end

      context 'when session_id filter is set' do
        let(:params) { { session_id: video.session.id } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include video.title }

        it { expect(response.body).not_to include video2.title }
      end

      context 'when limit param is set' do
        let(:params) { { limit: 1 } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when offset param is set' do
        let(:params) { { limit: 1, offset: 1 } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
