# frozen_string_literal: true

require 'spec_helper'

describe SessionCoPresentershipsController do
  let!(:session) { create(:immersive_session).tap { |s| s.co_presenters << current_user.presenter } }
  let(:current_user) { create(:presenter).user }
  let(:session_co_presentership) { SessionCoPresentership.last }

  before do
    sign_in current_user, scope: :user

    session.update({ former_start_at: 3.hours.ago })
    session_co_presentership.await_decision_on_changed_start_at!
  end

  describe 'GET :accept_changed_start_at' do
    it 'works' do
      get :accept_changed_start_at, params: { id: session_co_presentership.id }

      expect(response).to be_redirect
      expect(session_co_presentership.reload).to be_confirmed
    end
  end

  describe 'GET :decline_changed_start_at' do
    it 'works' do
      get :decline_changed_start_at, params: { id: session_co_presentership.id }

      expect(response).to be_redirect
      expect(SessionParticipation.count).to be_zero
    end
  end
end
