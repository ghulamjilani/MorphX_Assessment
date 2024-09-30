# frozen_string_literal: true

require 'spec_helper'

describe SessionInvitationButtonsPresenter do
  let(:ability) do
    ability = Object.new
    ability.extend(CanCan::Ability)
    ability
  end
  let(:current_user) { FactoryBot.create(:user) }

  context 'when given completely free session and invited participant' do
    let(:session) { create(:immersive_session) }

    it 'returns link to accept_invitation action' do
      ability.can :accept_or_reject_invitation, Session
      ability.can :obtain_free_trial_immersive_access, Session
      result = described_class.new({ model_invited_to: session, current_user: current_user,
                                     ability: ability }).to_s_for_tile
      expect(result).to include('accept_invitation')
    end
  end

  context 'when not allowed to accept/reject invitation' do
    it 'returns empty string' do
      result = described_class.new({ model_invited_to: Session.new,
                                     current_user: current_user,
                                     ability: ability }).to_s_for_tile
      expect(result).to be_blank
    end
  end
end
