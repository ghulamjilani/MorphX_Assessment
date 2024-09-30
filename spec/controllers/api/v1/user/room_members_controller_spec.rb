# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::RoomMembersController do
  let(:room_member_participant) { create(:room_member_participant) }
  let(:room_member_co_presenter) { create(:room_member_co_presenter, room: room) }
  let(:room_member_presenter) { create(:room_member_presenter, room: room) }
  let(:room) { room_member_participant.room }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:current_user) { room.presenter_user }
  let(:ban_reason) { create(:ban_reason) }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      render_views

      it 'responds with 200 and returns valid json' do
        get :index, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end

    describe 'POST allow_control:' do
      it 'does not fail' do
        post :allow_control, params: { room_id: room.id, id: room_member_co_presenter.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST disable_control:' do
      it 'does not fail' do
        post :disable_control, params: { room_id: room.id, id: room_member_co_presenter.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST mute:' do
      it 'does not fail' do
        post :mute, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST unmute:' do
      it 'does not fail' do
        post :unmute, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST mute_all:' do
      it 'does not fail' do
        post :mute_all, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST unmute_all:' do
      it 'does not fail' do
        post :unmute_all, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST start_video:' do
      it 'does not fail' do
        post :start_video, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST stop_video:' do
      it 'does not fail' do
        post :stop_video, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST start_all_videos:' do
      it 'does not fail' do
        post :start_all_videos, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST stop_all_videos:' do
      it 'does not fail' do
        post :stop_all_videos, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST ban_kick:' do
      let(:params) do
        {
          id: room_member_participant.id,
          room_id: room_member_participant.room_id,
          ban_reason_id: ban_reason.id
        }
      end

      it 'does not fail' do
        post :ban_kick, params: params, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST enable_backstage:' do
      it 'does not fail' do
        post :enable_backstage, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST disable_backstage:' do
      it 'does not fail' do
        post :disable_backstage, params: { room_id: room.id, id: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST enable_all_backstage:' do
      it 'does not fail' do
        post :enable_all_backstage, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST disable_all_backstage:' do
      it 'does not fail' do
        post :disable_all_backstage, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST pin:' do
      it 'does not fail' do
        post :pin, params: { room_id: room.id, room_member_ids: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST pin_only:' do
      it 'does not fail' do
        post :pin_only, params: { room_id: room.id, room_member_ids: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST unpin:' do
      it 'does not fail' do
        post :unpin, params: { room_id: room.id, room_member_ids: room_member_participant.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST unpin_all:' do
      it 'does not fail' do
        post :unpin_all, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
      end
    end
  end
end
