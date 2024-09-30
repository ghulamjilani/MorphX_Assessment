# frozen_string_literal: true
require 'spec_helper'

describe SessionInvitedImmersiveCoPresentership do
  let(:session) { create(:immersive_session) }
  let(:user) { create(:presenter).user }
  let!(:presentership) do
    create(:accepted_session_invited_immersive_co_presentership, session: session, presenter: user.presenter)
  end

  describe '#destroy' do
    before do
      session.co_presenters << user.presenter
      create(:organizer_session_pay_promise, abstract_session: session, co_presenter: user.presenter)
      presentership.destroy
    end

    it 'destroys corresponding OrganizerAbstractSessionPayPromise objects' do
      expect(OrganizerAbstractSessionPayPromise.count).to eq(0)
    end

    it 'destroys corresponding SessionCoPresentership objects' do
      expect(SessionCoPresentership.count).to eq(0)
    end

    it 'destroys corresponding SessionInvitedImmersiveCoPresentership objects' do
      expect(described_class.count).to eq(0)
    end
  end
end
