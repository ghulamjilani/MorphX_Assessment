# frozen_string_literal: true
require 'spec_helper'
require 'sidekiq/testing'

describe SessionInvitedImmersiveParticipantship do
  context 'when group session' do
    let(:session) { create(:immersive_session) }

    context 'when this user has already been paid for immersive access' do
      let(:user) { create(:participant).user }

      it 'is not allowed to be invited for this user' do
        session.immersive_participants << user.participant

        expect do
          session.session_invited_immersive_participantships.create!(participant: user.participant)
        end.to(raise_error(/Invited participant is already confirmed as participant of the session/))
      end
    end

    context 'when this user is at the same time an organizer' do
      let(:participant) { create(:participant, user: session.organizer) }

      it 'is not allowed to be invited for this user' do
        expect do
          session.session_invited_immersive_participantships.create!(participant: participant)
        end.to(raise_error(/Organizer could not be invited as participant/))
      end
    end

    context 'when this user is co-presenter' do
      let(:user) { create(:participant).user }
      let(:presenter) { create(:presenter, user: user) }

      it 'is not allowed to be invited for this user' do
        session.co_presenters << presenter
        expect do
          session.session_invited_immersive_participantships.create!(participant: user.participant)
        end.to(raise_error(/Invited participant is already confirmed as co-presenter of the session/))
      end
    end
  end

  describe 'reminders' do
    let(:session) { create(:immersive_session) }
    let(:participant) { create(:participant) }

    context 'when given pending invitation' do
      it 'disables reminders when invitation is rejected' do
        # SessionInvitedImmersiveParticipantship.first.reject!
        #
        # expect(SessionInvitedImmersiveParticipantship.first).to be_rejected
        # expect(SessionStartReminder).not_to have_scheduled(session.id, participant.user.id)
      end
    end
  end
end
