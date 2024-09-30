# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe FfmpegserviceAccountJobs::AuthenticateJob do
  describe '#perform' do
    let(:wa) { create(:ffmpegservice_account_rtmp, authentication: true) }

    before do
      wa
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates wa name' do
      expect do
        described_class.new.perform
        wa.reload
      end.to change(wa, :authentication).from(true).to(false)
    end
  end
end
