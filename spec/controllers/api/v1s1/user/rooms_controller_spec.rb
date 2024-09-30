# frozen_string_literal: true

require 'spec_helper'

describe Api::V1s1::User::RoomsController do
  let(:room) { create(:immersive_room_active) }
  let(:participation) { create(:session_participation, session: room.abstract_session) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:room_presenter) { room.presenter_user }
  let(:room_participant) { participation.participant.user }

  render_views

  before do
    stub_request(:any, /.*webrtcservice.com*/)
      .to_return(status: 200, body: '', headers: {})
  end

  describe '.json request format' do
    describe 'GET show:' do
      context 'when auth missing' do
        it 'responds with 200 and returns valid json' do
          get :show, params: { id: room.id }, format: :json

          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when auth present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: room.id }, format: :json
        end

        context 'when current user is session presenter' do
          let(:current_user) { room_presenter }

          it 'responds with 200 and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when current user is session participant' do
          let(:current_user) { room_participant }

          it 'responds with 200 and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end
    end

    describe 'PUT update: start' do
      let(:current_user) { room_presenter }

      before do
        room.update_columns(status: 'awaiting')
        request.headers['Authorization'] = auth_header_value
        put :update, params: params, format: :json
      end

      context 'when update: action = start' do
        let(:params) { { id: room.id, room: { action: 'start' } } }

        it 'responds with 200 and returns valid json' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'PUT update:' do
      let(:current_user) { room_presenter }

      before do
        request.headers['Authorization'] = auth_header_value
        put :update, params: params, format: :json
      end

      context 'when update: action = stop' do
        let(:params) { { id: room.id, room: { action: 'stop' } } }

        it 'responds with 200 and returns valid json' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when update: is_screen_share_available = true' do
        let(:params) { { id: room.id, room: { is_screen_share_available: true } } }

        it 'responds with 200 and returns valid json' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given action param set to start_record' do
        let(:params) { { id: room.id, room: { action: 'start_record' } } }

        it { expect(response).to be_successful }
      end

      context 'when given action param set to stop_record' do
        let(:params) { { id: room.id, room: { action: 'stop_record' } } }

        it { expect(response).to be_successful }
      end

      context 'when given action param set to pause_record' do
        let(:params) { { id: room.id, room: { action: 'pause_record' } } }

        it { expect(response).to be_successful }
      end

      context 'when given action param set to resume_record' do
        let(:params) { { id: room.id, room: { action: 'resume_record' } } }

        it { expect(response).to be_successful }
      end

      context 'when update: switch_screen_share_ability = false' do
        let(:params) { { id: room.id, room: { is_screen_share_available: false } } }

        it 'responds with 200 and returns valid json' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given room_members_attributes params' do
        let(:room_member_participant) do
          create(:room_member_participant, pinned: pinned, room: create(:immersive_room_active))
        end
        let(:room) { room_member_participant.room }
        let(:params) do
          {
            id: room.id,
            room: {
              room_members_attributes: room_members_attributes
            }
          }
        end

        context 'when given room_member pinned=true' do
          let(:pinned) { false }
          let(:room_members_attributes) { [{ id: room_member_participant.id, pinned: true }] }

          it 'pins room_member' do
            expect(room_member_participant.reload.pinned).to be_truthy
          end
        end

        context 'when given room_member pinned=false' do
          let(:pinned) { true }
          let(:room_members_attributes) { [{ id: room_member_participant.id, pinned: false }] }

          it 'unpins room_member' do
            expect(room_member_participant.reload.pinned).to be_falsey
          end
        end
      end

      context 'when given sesstion allow_chat param' do
        let(:params) do
          {
            id: room.id,
            room: {
              session_attributes: {
                id: room.session.id,
                allow_chat: allow_chat
              }
            }
          }
        end

        context 'when allow_chat is true' do
          let(:allow_chat) { true }

          it { expect(response).to be_successful }

          it { expect(room.session.reload.allow_chat).to eq(true) }
        end

        context 'when allow_chat is false' do
          let(:allow_chat) { false }

          it { expect(response).to be_successful }

          it { expect(room.session.reload.allow_chat).to eq(false) }
        end
      end
    end
  end
end
