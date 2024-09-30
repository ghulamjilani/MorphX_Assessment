# frozen_string_literal: true

require 'spec_helper'

describe LivestreamersController do
  let(:session) do
    create(:immersive_session).tap do |s|
      s.session_invited_immersive_participantships.create(participant: current_user.participant)
      SessionInvitedImmersiveParticipantship.last.update_attribute(:status, 'accepted')

      s.livestreamers.create!(participant: current_user.participant, free_trial: false)
    end
  end
  let(:current_user) { create(:participant).user }
  let(:livestreamer) { Livestreamer.last }

  before do
    session

    sign_in current_user, scope: :user

    session.update({ former_start_at: 3.hours.ago })

    livestreamer.await_decision_on_changed_start_at!
  end

  describe 'GET :accept_changed_start_at' do
    it 'works' do
      get :accept_changed_start_at, params: { id: livestreamer.id }

      expect(response).to be_redirect
      expect(livestreamer.reload).to be_confirmed

      get :accept_changed_start_at, params: { id: livestreamer.id }
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET :decline_changed_start_at' do
    it 'works' do
      id = livestreamer.id
      get :decline_changed_start_at, params: { id: id }

      expect(response).to be_redirect
      expect(SessionParticipation.count).to be_zero

      get :decline_changed_start_at, params: { id: id }
      expect(flash[:error]).to be_present
    end
  end
end
