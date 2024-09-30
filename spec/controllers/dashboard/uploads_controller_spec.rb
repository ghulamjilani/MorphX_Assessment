# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::UploadsController do
  before { sign_in current_user, scope: :user }

  let(:current_user) { create(:user) }

  describe 'POST :publish_toggle ->' do
    render_views

    context 'when recording.blank? ->' do
      before { post :publish_toggle, params: { id: 10 }, format: :json }

      it { expect(response).to have_http_status :not_found }
      it { expect(response.body).to include 'No video found' }
    end

    describe 'recording exists ->' do
      let!(:recording) { create(:recording) }
      let(:params) do
        { id: recording.id, crop_seconds: 50, cropped_duration: 60_000 }
      end

      context 'when cannot?(:manipulate, recording) ->' do
        before { post :publish_toggle, params: params, format: :json }

        it { expect(response).to have_http_status :unauthorized }
        it { expect(response.body).to include 'Access denied' }
      end

      context 'when recording.published? ->' do
        before do
          recording.update(published: DateTime.now, crop_seconds: nil, cropped_duration: nil)
          allow(controller).to receive(:cannot?).with(:transcode_recording, recording.channel).and_return(false)
          post :publish_toggle, params: params, format: :json
          recording.reload
        end

        it { expect(response).to have_http_status :ok }
        it { expect(recording.published).to be_nil }
        it { expect(recording.crop_seconds).to be_nil }
        it { expect(recording.cropped_duration).to be_nil }
      end

      context 'when recording not published ->' do
        before do
          allow(controller).to receive(:cannot?).with(:transcode_recording, recording.channel).and_return(false)
          post :publish_toggle, params: params, format: :json
          recording.reload
        end

        it { expect(response).to have_http_status :ok }
        it { expect(recording.published).to be_truthy }
        it { expect(recording.crop_seconds).to eql params[:crop_seconds] }
        it { expect(recording.cropped_duration).to eql params[:cropped_duration] }
      end
    end
  end

  describe 'POST :publish ->' do
    render_views

    context 'when recording.blank? ->' do
      before { post :publish, params: { id: 10 }, format: :json }

      it { expect(response).to have_http_status :not_found }
      it { expect(response.body).to include 'No video found' }
    end

    describe 'recording exists ->' do
      let!(:recording) { create(:recording) }
      let(:params) do
        { id: recording.id, crop_seconds: 50, cropped_duration: 60_000 }
      end

      context 'when cannot?(:manipulate, recording) ->' do
        before { post :publish, params: params, format: :json }

        it { expect(response).to have_http_status :unauthorized }
        it { expect(response.body).to include 'Access denied' }
      end

      context 'when recording.published? ->' do
        before do
          recording.update(published: DateTime.now, crop_seconds: nil, cropped_duration: nil)
          allow(controller).to receive(:cannot?).with(:transcode_recording, recording.channel).and_return(false)
          post :publish, params: params, format: :json
          recording.reload
        end

        it { expect(response).to have_http_status :ok }

        it { expect(recording.published).not_to be_nil }

        it { expect(recording.crop_seconds).to be_nil }

        it { expect(recording.cropped_duration).to be_nil }
      end

      context 'when recording not published ->' do
        before do
          allow(controller).to receive(:cannot?).with(:transcode_recording, recording.channel).and_return(false)
          post :publish, params: params, format: :json
          recording.reload
        end

        it { expect(response).to have_http_status :ok }
        it { expect(recording.published).to be_truthy }
        it { expect(recording.crop_seconds).to eql params[:crop_seconds] }
        it { expect(recording.cropped_duration).to eql params[:cropped_duration] }
      end
    end
  end

  describe 'POST :group_move' do
    let(:recording1) { create(:recording_published) }
    let(:recording2) { create(:recording_published, channel: recording1.channel) }
    let(:channel) { create(:listed_channel, organization: recording1.channel.organization) }
    let(:current_user) { recording1.channel.organizer }

    before { sign_in current_user, scope: :user }

    it 'moves recordings between channels' do
      post :group_move, format: :json, params: { channel_id: channel.id, video_ids: [recording1.id, recording2.id] }
      v1 = Recording.find recording1.id
      v2 = Recording.find recording2.id
      expect(response).to have_http_status :ok
      expect(v1.channel_id).to eq(channel.id)
      expect(v2.channel_id).to eq(channel.id)
    end
  end
end
