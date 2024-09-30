# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::HasOrganizationMemberships do
  describe '#current_organization_participant?' do
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }

    before do
      user.update(current_organization_id: organization_id)
    end

    context 'when given organization owner' do
      let(:user) { organization.user }

      it { expect { user.current_organization_participant? }.not_to raise_error }

      it { expect(user).to be_current_organization_participant }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { expect { user.current_organization_participant? }.not_to raise_error }

      it { expect(user).to be_current_organization_participant }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending, organization: organization).user }

      it { expect { user.current_organization_participant? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_participant }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest, organization: organization).user }

      it { expect { user.current_organization_participant? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_participant }
    end

    context 'when given user without current organization' do
      let(:user) { create(:user) }
      let(:organization_id) { nil }

      it { expect { user.current_organization_participant? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_participant }
    end
  end

  describe '#current_organization_guest?' do
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }

    before do
      user.update(current_organization_id: organization_id)
    end

    context 'when given organization owner' do
      let(:user) { organization.user }

      it { expect { user.current_organization_guest? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_guest }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { expect { user.current_organization_guest? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_guest }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending, organization: organization).user }

      it { expect { user.current_organization_guest? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_guest }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest, organization: organization).user }

      it { expect { user.current_organization_guest? }.not_to raise_error }

      it { expect(user).to be_current_organization_guest }
    end

    context 'when given user without current organization' do
      let(:user) { create(:user) }
      let(:organization_id) { nil }

      it { expect { user.current_organization_guest? }.not_to raise_error }

      it { expect(user).not_to be_current_organization_guest }
    end
  end

  describe '#current_organization_membership' do
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }

    before do
      user.update(current_organization_id: organization_id)
    end

    context 'when given organization owner' do
      let(:user) { organization.user }

      it { expect { user.current_organization_membership }.not_to raise_error }

      it { expect(user.current_organization_membership).to be_blank }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { expect { user.current_organization_membership }.not_to raise_error }

      it { expect(user.current_organization_membership).to be_present }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending, organization: organization).user }
      let(:organization_id) { nil }

      it { expect { user.current_organization_membership }.not_to raise_error }

      it { expect(user.current_organization_membership).to be_blank }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest, organization: organization).user }

      it { expect { user.current_organization_membership }.not_to raise_error }

      it { expect(user.current_organization_membership).to be_present }
    end

    context 'when given user without current organization' do
      let(:user) { create(:user) }
      let(:organization_id) { nil }

      it { expect { user.current_organization_membership }.not_to raise_error }

      it { expect(user.current_organization_membership).to be_blank }
    end
  end

  describe '#current_organization_membership_type' do
    let(:organization) { create(:organization) }
    let(:organization_id) { organization.id }

    before do
      user.update(current_organization_id: organization_id)
    end

    context 'when given organization owner' do
      let(:user) { organization.user }

      it { expect { user.current_organization_membership_type }.not_to raise_error }

      it { expect(user.current_organization_membership_type).to be_present }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { expect { user.current_organization_membership_type }.not_to raise_error }

      it { expect(user.current_organization_membership_type).to be_present }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending, organization: organization).user }
      let(:organization_id) { nil }

      it { expect { user.current_organization_membership_type }.not_to raise_error }

      it { expect(user.current_organization_membership_type).to be_blank }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest, organization: organization).user }

      it { expect { user.current_organization_membership_type }.not_to raise_error }

      it { expect(user.current_organization_membership_type).to be_present }
    end

    context 'when given user without current organization' do
      let(:user) { create(:user) }
      let(:organization_id) { nil }

      it { expect { user.current_organization_membership_type }.not_to raise_error }

      it { expect(user.current_organization_membership_type).to be_blank }
    end
  end
end
