# frozen_string_literal: true

require 'spec_helper'

describe ObtainImmersiveAccessToSession do
  context 'when invited participant' do
    let(:user) { create(:user) }

    let(:current_user) { create(:participant, user: user).user }

    let!(:session) do
      session = create(:free_trial_immersive_session)
      session.session_invited_immersive_participantships.create(participant: current_user.participant)

      session
    end

    it 'does not fail' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      expect(interactor.execute).to be true
    end

    it 'does not' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      expect(interactor.success_message).not_to be_blank
    end

    it 'does' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      expect(interactor.error_message).to be_blank
    end

    it 'mark participation as accepted' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute

      expect(SessionInvitedImmersiveParticipantship.first).to be_accepted
    end

    it 'adds participant to list of participants' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute

      expect(session.reload.immersive_participants).to include(current_user.participant)
    end
  end

  context 'when invited co-presenter' do
    let(:user) { create(:user) }

    let(:current_user) { create(:presenter, user: user).user.reload }
    let(:session) do
      session = create(:completely_free_session).tap do |s|
        s.status = ::Session::Statuses::PUBLISHED
        s.save!
      end
      session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
      session
    end

    it { expect(session.co_presenters.count).to be_zero }

    it 'does not fail' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute
      expect(interactor.error_message).to be_blank
    end

    it 'does not ' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute
      expect(interactor.success_message).not_to be_blank
    end

    it 'mark membership as accepted' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute

      expect(SessionInvitedImmersiveCoPresentership.first).to be_accepted
    end

    it 'adds buyer to list of co-presenters' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute
      expect(session.co_presenters.first).to eq(current_user.presenter)
    end

    it 'buyer to list of co-presenters' do
      interactor = described_class.new(session, current_user)
      interactor.free_type_is_chosen!
      interactor.execute
      expect(session.co_presenters.count).to eq(1)
    end
  end
end
