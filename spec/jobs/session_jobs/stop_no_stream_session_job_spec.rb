# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::StopNoStreamSessionJob do
  let(:session) { create(:livestream_session) }
  let(:client) { instance_double(Sender::Ffmpegservice) }

  it { expect { described_class.new.perform(session.id) }.not_to raise_error }

  context 'when stream not connected' do
    before do
      allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
      allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'No' } })
    end

    it 'stops session' do
      expect do
        described_class.new.perform(session.id)
        session.reload
      end.to change(session, :stopped_at)
    end
  end

  context 'when stream connected' do
    before do
      allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
      allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'Yes' } })
    end

    it 'does not stop session' do
      expect { described_class.new.perform(session.id) }.not_to change(session, :stopped_at)
    end
  end

  context 'when no response from ffmpegservice' do
    before do
      allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
      allow(client).to receive(:stats_transcoder).and_return(nil)
    end

    it { expect { described_class.new.perform(session.id) }.not_to raise_error }

    it 'does not stop session' do
      expect do
        described_class.new.perform(session.id)
        session.reload
      end.not_to change(session, :stopped_at)
    end

    it { expect { described_class.new.perform(session.id) }.to change(described_class.jobs, :size) }
  end
end
