# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe FfmpegserviceAccountJobs::RenameJob do
  describe '#perform' do
    let(:wa) { create(:ffmpegservice_account_assigned) }

    before do
      wa
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates wa name' do
      expect do
        described_class.new.perform
        wa.reload
      end.to change(wa, :name)
    end
  end
end
