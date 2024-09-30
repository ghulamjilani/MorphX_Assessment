# frozen_string_literal: true

require 'spec_helper'

describe SessionJobs::PingLivestream do
  context 'when session is livestream(ffmpegservice)' do
    let(:session) do
      session = create(:livestream_session)
      session.organization.update_column(:stop_no_stream_sessions, 5)
      session.update_column(:start_at, 1.minute.ago)
      session
    end
    let(:client) { instance_double(Sender::Ffmpegservice) }

    it { expect { described_class.new.perform(session.room.id) }.not_to raise_error }

    context 'when stream is delivered to ffmpegservice' do
      before do
        allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
        allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'Yes' } })
        allow(client).to receive(:state_transcoder).and_return({ state: 'started' })
        allow(client).to receive(:transcoder_active?).and_return(true)
      end

      it { expect { described_class.new.perform(session.room.id) }.not_to change(SessionJobs::StopNoStreamSessionJob.jobs, :size) }
    end

    context 'when no stream is deliverd to ffmpegservice' do
      before do
        allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
        allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'No' } })
        allow(client).to receive(:state_transcoder).and_return({ state: 'started' })
        allow(client).to receive(:transcoder_active?).and_return(false)
        session.room.active!
      end

      it { expect { described_class.new.perform(session.room.id) }.to change(SessionJobs::StopNoStreamSessionJob.jobs, :size).and change(SessionJobs::StopNoStreamSessionNotificationJob.jobs, :size) }
    end
  end

  context 'when session is interactive(webrtcservice)' do
    let(:session) { create(:session) }

    it { expect { described_class.new.perform(session.room.id) }.not_to raise_error }
  end
end
