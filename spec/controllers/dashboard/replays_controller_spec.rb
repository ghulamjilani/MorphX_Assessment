# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::ReplaysController do
  describe 'GET :index' do
    render_views

    let(:current_user) { video.channel.organizer }

    before { sign_in current_user, scope: :user }

    describe '.json request format' do
      let(:video) { create(:video) }
      let(:channel) { video.channel }
      let(:video_with_error) { create(:video_with_error, room: video.room) }

      it 'returns json' do
        get :index, format: :json, params: { id: channel.id }
        expect(response).to be_successful
        expect do
          JSON.parse(response.body)
        end.not_to raise_error, response.body
      end

      it 'contains video id in models list' do
        get :index, format: :json, params: { id: channel.id }
        expect(JSON.parse(response.body)['models'].map { |model| model['id'].to_i }).to include(video.id)
      end

      it 'does not contain id of video with status "error" in models list' do
        get :index, format: :json, params: { id: channel.id }
        expect(JSON.parse(response.body)['models'].map { |model| model['id'].to_i }).not_to include(video_with_error.id)
      end
    end
  end

  describe 'POST :group_move' do
    let(:current_user) { video1.channel.organizer }
    let(:video1) { create(:video_published_on_listed_channel) }
    let(:video2) { create(:recorded_session, channel: video1.channel).records.first }
    let(:channel) { create(:listed_channel, organization: video1.channel.organization) }

    before { sign_in current_user, scope: :user }

    it 'moves videos between channels' do
      post :group_move, format: :json, params: { channel_id: channel.id, video_ids: [video1.id, video2.id] }
      v1 = Video.find video1.id
      v2 = Video.find video2.id
      expect(response).to have_http_status :ok
      expect(v1.channel.id).to eq(channel.id)
      expect(v2.channel.id).to eq(channel.id)
    end
  end
end
