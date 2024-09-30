# frozen_string_literal: true
require 'spec_helper'

describe OrganizationMembership, 'validations' do
  let(:organization) { create(:organization) }

  it 'allows only unique employee combinations' do
    user = create(:user, email: 'userX@gmail.com')
    create :organization_membership, organization: organization, user: user

    expect do
      create :organization_membership, organization: organization, user: user
    end.to raise_error(/has already been taken/)
  end

  it 'does not allow to invite owner' do
    expect do
      create :organization_membership, organization: organization, user: organization.user
    end.to raise_error(/organization owner cannot be invited/)
  end

  describe '#active?' do
    let(:described_subject) { membership.active? }

    context 'when membership is active' do
      let(:membership) { build(:organization_membership_active) }

      it { expect(described_subject).to be_truthy }
    end
  end

  describe '#active!' do
    let(:described_subject) { membership.active! }
    let(:membership) do
      create(%i[organization_membership_pending organization_membership_suspended
                organization_membership_cancelled].sample)
    end

    it { expect { membership.active!; membership.reload }.to change(membership, :status).to('active') }

    it {
      expect do
        membership.active!;
        membership.user.reload
      end.to change(membership.user, :current_organization_id).to(membership.organization_id)
    }

    it { expect { described_subject }.not_to raise_error }
  end

  describe '#active!' do
    let(:described_subject) { membership.active! }
    let(:membership) do
      create(%i[organization_membership_pending organization_membership_suspended
                organization_membership_cancelled].sample)
    end

    it { expect { membership.active!; membership.reload }.to change(membership, :status).to('active') }

    it {
      expect do
        membership.active!;
        membership.user.reload
      end.to change(membership.user, :current_organization_id).from(nil).to(membership.organization_id)
    }

    it { expect { described_subject }.not_to raise_error }
  end

  describe '#notify_user_about_adding' do
    let(:organization_membership) { create(:organization_membership_cancelled) }
    let(:organization) { create(:organization) }
    let(:user) { create(:user) }

    before do
      mailer = double
      allow(mailer).to receive(:deliver_later)
      allow(CompanyMailer).to receive(:employee_invited).and_return(mailer)
    end

    it 'sends email when membership is created' do
      described_class.create(user: user, organization: organization)

      expect(CompanyMailer).to have_received(:employee_invited)
    end

    it 'sends email when membership is updated' do
      organization_membership.update(status: :pending)

      expect(CompanyMailer).to have_received(:employee_invited)
    end
  end

  describe '#notify_user_about_rejecting' do
    before do
      mailer = double
      allow(mailer).to receive(:deliver_later)
      allow(CompanyMailer).to receive(:employee_rejected).and_return(mailer)
    end

    context 'when given participant user' do
      let(:organization_membership) { build(:organization_membership) }

      it { expect { organization_membership.send(:notify_user_about_rejecting) }.not_to raise_error }

      it 'sends email to employer' do
        organization_membership.send(:notify_user_about_rejecting)
        expect(CompanyMailer).to have_received(:employee_rejected)
      end
    end

    context 'when given guest user' do
      let(:organization_membership) { build(:organization_membership_guest) }

      it { expect { organization_membership.send(:notify_user_about_rejecting) }.not_to raise_error }

      it 'does not send email to employer' do
        organization_membership.send(:notify_user_about_rejecting)
        expect(CompanyMailer).not_to have_received(:employee_rejected)
      end
    end
  end
end
