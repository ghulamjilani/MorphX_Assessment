# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::SessionInvitedImmersiveParticipantshipAbility do
  let(:ability) { described_class.new(current_user) }

  describe '#change_status_as_participant' do
    context 'when participantship has status pending' do
      let(:participantship) { create(:session_invited_immersive_participantship) }

      context 'when user is the invited participant' do
        let(:current_user) { participantship.participant.user }

        it { expect(ability).to be_able_to :change_status_as_participant, participantship }
      end

      context 'when user is not the invited participant' do
        let(:current_user) { create(:user) }

        it { expect(ability).not_to be_able_to :change_status_as_participant, participantship }
      end
    end

    context 'when participantship has status accepted/rejected' do
      let(:participantship) do
        create(%i[accepted_session_invited_immersive_participantship
                  rejected_session_invited_immersive_participantship].sample)
      end
      let(:current_user) { participantship.participant.user }

      it { expect(ability).not_to be_able_to :change_status_as_participant, participantship }
    end
  end

  describe '#destroy_invitation' do
    context 'when invitations has status pending' do
      let(:participantship) { create(:session_invited_immersive_participantship) }

      context 'when user is session presenter' do
        let(:current_user) { participantship.session.presenter.user }

        it { expect(ability).to be_able_to :destroy_invitation, participantship }
      end

      context 'when user is not session presenter' do
        let(:current_user) { create(:user) }

        it { expect(ability).not_to be_able_to :destroy_invitation, participantship }
      end
    end

    context 'when invitations has status accepted' do
      let(:participantship) { create(:accepted_session_invited_immersive_participantship) }
      let(:current_user) { participantship.session.presenter.user }

      it { expect(ability).not_to be_able_to :destroy_invitation, participantship }
    end
  end
end
