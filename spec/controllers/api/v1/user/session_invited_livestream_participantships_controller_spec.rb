# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::SessionInvitedLivestreamParticipantshipsController do
  let(:participantship) { create(:session_invited_livestream_participantship) }
  let(:invited_participant_user) { create(:user) }
  let(:session) { participantship.session }
  let(:room) { session.room }
  let(:current_user) { session.presenter.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:participantship_accepted) { create(:accepted_session_invited_livestream_participantship, session: session) }

  describe '.json request format' do
    render_views

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      render_views

      it 'does not fail and returns valid JSON' do
        get :index, params: { room_id: room.id }, format: :json
        expect(response).to be_successful
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end

    describe 'GET show:' do
      render_views

      it 'does not fail and returns valid JSON' do
        get :index, params: { room_id: room.id, id: participantship.id }, format: :json
        expect(response).to be_successful
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end

    describe 'POST create:' do
      it 'invites user by id' do
        expect do
          post :create, params: { room_id: room.id, user_id: invited_participant_user.id }, format: :json
          expect(response).to be_successful
        end.to change(SessionInvitedLivestreamParticipantship, :count).by(1)
      end

      it 'invites existing user by email' do
        expect do
          post :create, params: { room_id: room.id, email: invited_participant_user.email }, format: :json
          expect(response).to be_successful
        end.to change(SessionInvitedLivestreamParticipantship, :count).by(1)
      end

      it 'invites existing user by email ignoring case' do
        expect do
          post :create, params: { room_id: room.id, email: invited_participant_user.email.upcase }, format: :json
          expect(response).to be_successful
        end.to change(SessionInvitedLivestreamParticipantship, :count).by(1)
      end

      it 'invites new user by email' do
        expect do
          post :create, params: { room_id: room.id, email: 'foo@bar.com' }, format: :json
          expect(response).to be_successful
        end.to change(SessionInvitedLivestreamParticipantship, :count).by(1)
      end

      it 'returns 422 when email is invalid' do
        expect do
          post :create, params: { room_id: room.id, email: 'foo@' }, format: :json
          expect(response).to have_http_status :unprocessable_entity
        end.not_to change(SessionInvitedLivestreamParticipantship, :count)
      end
    end

    describe 'PUT update:' do
      let(:session) { create(:published_session, livestream_purchase_price: 0, livestream_free: true) }
      let(:participantship) { create(:session_invited_livestream_participantship, session: session) }
      let(:current_user) { participantship.participant.user }

      context 'when session is free' do
        let(:session) { create(:published_session, livestream_purchase_price: 0, livestream_free: true) }

        it 'accepts pending invitation' do
          participantship
          expect do
            put :update,
                params: { id: participantship.id, status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED }, format: :json
            expect(response).to be_successful
          end.to change {
                   participantship.reload.status
                 }.to(ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)
        end
      end

      it 'rejects pending invitation' do
        participantship
        expect do
          put :update,
              params: { id: participantship.id, status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED }, format: :json
          expect(response).to be_successful
        end.to change {
                 participantship.reload.status
               }.to(ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
      end

      it 'does not allow to update accepted invitation' do
        participantship_accepted
        expect do
          put :update,
              params: { id: participantship_accepted.id, status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED }, format: :json
          expect(response).not_to be_successful
        end.not_to change(participantship_accepted, :status)
      end
    end

    describe 'DELETE destroy:' do
      it 'deletes participantship' do
        expect do
          delete :destroy, params: { id: participantship.id }, format: :json
          expect(response).to be_successful
        end.to change(SessionInvitedLivestreamParticipantship, :count).by(-1)
      end

      it 'does not delete accepted participantship' do
        participantship_accepted
        expect do
          delete :destroy, params: { id: participantship_accepted.id }, format: :json
          expect(response).not_to be_successful
        end.not_to change(SessionInvitedLivestreamParticipantship, :count)
      end
    end
  end
end
