# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe VideoJobs::CreateMonitorJob do
  let(:session) { create(:immersive_session, duration: 15, recorded_access_cost: 10) }

  before do
    stub_request(:any, /.*chat.webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  context 'when video missing' do
    context 'when session should be checked' do
      before do
        session.update_columns(start_at: 2.hours.ago)
      end

      it { expect { described_class.new.perform }.not_to raise_error }

      it 'notifies about missing video' do
        job = described_class.new
        allow(job).to receive(:send_notification)
        job.perform

        expect(job).to have_received(:send_notification).once.with(session.id)
      end
    end

    context 'when session should not be checked' do
      before do
        session.update_columns(start_at: 3.hours.ago)
      end

      it { expect { described_class.new.perform }.not_to raise_error }

      it 'does not notify about missing video' do
        job = described_class.new
        allow(job).to receive(:send_notification)
        job.perform

        expect(job).not_to have_received(:send_notification)
      end
    end
  end

  context 'when video present' do
    let(:session) { create(:video_published).room.session }

    before do
      session.update_columns(start_at: 2.hours.ago)
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'does not notify about missing video' do
      job = described_class.new
      allow(job).to receive(:send_notification)
      job.perform

      expect(job).not_to have_received(:send_notification)
    end
  end
end
