# frozen_string_literal: true

require 'spec_helper'

describe SessionParticipationsController do
  let(:session) do
    create(:immersive_session).tap do |s|
      s.session_invited_immersive_participantships.create(participant: current_user.participant)
      SessionInvitedImmersiveParticipantship.last.update_attribute(:status, 'accepted')

      s.immersive_participants << current_user.participant
    end
  end
  let(:current_user) { create(:participant).user }
  let(:session_participation) { SessionParticipation.last }

  before do
    session

    sign_in current_user, scope: :user

    session.update({ former_start_at: 3.hours.ago })
    session_participation.await_decision_on_changed_start_at!
  end

  describe 'GET :accept_changed_start_at' do
    it 'works' do
      get :accept_changed_start_at, params: { id: session_participation.id }

      expect(response).to be_redirect
      expect(session_participation.reload).to be_confirmed
    end
  end

  describe 'GET :decline_changed_start_at' do
    it 'works' do
      get :decline_changed_start_at, params: { id: session_participation.id }

      expect(response).to be_redirect
      expect(SessionParticipation.count).to be_zero
    end
  end
end
