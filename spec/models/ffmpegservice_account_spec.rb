# frozen_string_literal: true
require 'spec_helper'

describe FfmpegserviceAccount do
  describe '#authentication_on!' do
    let(:ffmpegservice_account) { create(:ffmpegservice_account, authentication: false) }

    it 'changes authentication to true' do
      ffmpegservice_account.authentication_on!
      expect(ffmpegservice_account.authentication).to eq(true)
    end
  end

  describe '#authentication_off!' do
    let!(:ffmpegservice_account) { create(:ffmpegservice_account, authentication: true) }

    it 'changes authentication to true' do
      ffmpegservice_account.authentication_off!
      expect(ffmpegservice_account.authentication).to eq(false)
    end
  end

  describe '#stream_status_changed' do
    let!(:ffmpegservice_account) { create(:ffmpegservice_account, stream_status: 'off') }

    it 'updates session service_status' do
      allow(ffmpegservice_account).to receive(:stream_status_changed)
      ffmpegservice_account.stream_up!
    end
  end

  describe '#assign_organization' do
    let(:ffmpegservice_account) { build(:ffmpegservice_account, organization: nil) }
    let(:organization) { create(:organization) }

    it { expect { ffmpegservice_account.assign_organization(organization) }.not_to raise_error }

    it { expect { ffmpegservice_account.assign_organization(organization) }.to change(ffmpegservice_account, :organization) }
  end
end
