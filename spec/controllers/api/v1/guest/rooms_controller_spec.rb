# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Guest::RoomsController do
  let(:room) { create(:immersive_room_active) }
  let(:room_member) { create(:room_member_guest, room: room) }
  let(:guest) { room_member.guest }
  let(:auth_header_value) { "Bearer #{JwtAuth.guest(guest)}" }

  render_views

  before do
    stub_request(:any, /.*webrtcservice.com*/)
      .to_return(status: 200, body: '', headers: {})
  end

  describe '.json request format' do
    describe 'GET show:' do
      before do
        request.headers['Authorization'] = auth_header_value
        get :show, params: { id: room.id }, format: :json
      end

      context 'when current member is banned' do
        let(:room_member) { create(:room_member_guest_banned, room: room) }

        it 'responds with 401 and returns valid json' do
          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'POST join_interactive_by_token:' do
      let(:interactive_access_token) { create(:interactive_access_token_shared_with_guests, session: room.session) }

      before do
        request.headers['Authorization'] = auth_header_value
        post :join_interactive_by_token, params: { token: interactive_access_token.token }, format: :json
      end

      context 'when guest with existing room member enters the room' do
        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when guest enters the room first time' do
        let(:guest) { create(:guest) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when current guest is banned' do
        let(:room_member) { create(:room_member_guest_banned, room: room) }
        let(:guest) { room_member.guest }

        it 'responds with 401 and returns valid json' do
          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
