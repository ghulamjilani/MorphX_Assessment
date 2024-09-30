# frozen_string_literal: true

require 'spec_helper'

describe BlockingNotificationPresenter do
  let(:ability) do
    ability = Object.new
    ability.extend(CanCan::Ability)
    ability.can :accept_or_reject_invitation, Session
    ability.can :purchase_immersive_access, Session
    ability
  end

  describe '#models_invited_to' do
    let(:session) { create(:published_session) }
    let(:user) { create(:participant).user }

    it { expect(described_class.new(user, ability).models_invited_to).to eq([]) }

    it 'works' do
      session.session_invited_immersive_participantships.create(participant: user.participant)
      expect(described_class.new(user, ability).models_invited_to).to eq([session])
    end
  end
end
