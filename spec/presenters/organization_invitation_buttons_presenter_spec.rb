# frozen_string_literal: true

require 'spec_helper'

describe OrganizationInvitationButtonsPresenter do
  let(:ability) do
    ability = Object.new
    ability.extend(CanCan::Ability)
    ability
  end
  let(:organization_membership) { create(:organization_membership_pending) }
  let(:organization) { organization_membership.organization }

  context 'when given invited user and organization' do
    let(:current_user) { organization_membership.user }

    it 'returns link to accept_invitation action' do
      ability.can :accept_or_reject_invitation, Organization
      result = described_class.new({ model_invited_to: organization, current_user: current_user,
                                     ability: ability }).to_s_for_dashboard
      expect(result).to include('accept_invitation')
    end
  end

  context 'when not allowed to accept/reject invitation' do
    let(:current_user) { create(:user) }

    it 'returns empty string' do
      result = described_class.new({ model_invited_to: Organization.new,
                                     current_user: current_user,
                                     ability: ability }).to_s_for_dashboard
      expect(result).to be_blank
    end
  end
end
