# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::ActsAsAbstractSession do
  let(:session) do
    session = create(:livestream_session, duration: 60)
    session.organization.update_column(:stop_no_stream_sessions, 5)
    session.update_column(:start_at, 1.minute.ago)
    session.room.active!
    session
  end
  let(:client) { instance_double(Sender::Ffmpegservice) }

  describe '#duration_change_times_left_cache_key' do
    it { expect { session.duration_change_times_left_cache_key }.not_to raise_error }

    it { expect(session.duration_change_times_left_cache_key).to be_present }
  end

  describe '#duration_change_times_left' do
    it { expect { session.duration_change_times_left }.not_to raise_error }

    it { expect(session.duration_change_times_left).to be_present }
  end

  describe '#duration_change_times_left=' do
    let(:times_left) { 15 }

    it { expect { session.duration_change_times_left = times_left }.to change(session, :duration_change_times_left).to times_left }
  end

  describe '#decrement_duration_change_times' do
    it { expect { session.decrement_duration_change_times }.to change(session, :duration_change_times_left).by(-1) }

    context 'when duration_change_times_left is 0' do
      before do
        session.duration_change_times_left = 0
      end

      it { expect { session.decrement_duration_change_times }.not_to change(session, :duration_change_times_left) }
    end

    context 'when duration_change_times_left is -1' do
      before do
        session.duration_change_times_left = -1
      end

      it { expect { session.decrement_duration_change_times }.not_to change(session, :duration_change_times_left) }
    end
  end

  describe '#increase_duration' do
    it { expect { session.increase_duration }.to change(session, :duration) }

    context 'when given argument' do
      it { expect { session.increase_duration(5) }.to change(session, :duration).by(5) }
    end

    context 'when duration_change_times_left is 0' do
      before do
        session.duration_change_times_left = 0
      end

      it { expect { session.increase_duration }.not_to change(session, :duration) }
    end

    context 'when duration_change_times_left is -1' do
      before do
        session.duration_change_times_left = -1
      end

      it { expect { session.increase_duration }.to change(session, :duration) }
    end
  end

  describe '#decrease_duration' do
    it { expect { session.decrease_duration }.to change(session, :duration) }

    it { expect { session.decrease_duration(5) }.to change(session, :duration).by(-5) }
  end

  describe '.schedule_stop_no_stream_job' do
    it { expect { session.schedule_stop_no_stream_job }.not_to raise_error }

    context 'when stream is inactive' do
      before do
        allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
        allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'No' } })
        allow(client).to receive(:state_transcoder).and_return({ state: 'started' })
        allow(client).to receive(:transcoder_active?).and_return(false)
      end

      it { expect { session.schedule_stop_no_stream_job }.not_to raise_error }

      it { expect { session.schedule_stop_no_stream_job }.to change(SessionJobs::StopNoStreamSessionJob.jobs, :size) }
    end
  end

  describe '.remove_stop_no_stream_job' do
    it { expect { session.schedule_stop_no_stream_job }.not_to raise_error }
  end

  describe '.job_name_cache_key' do
    let(:session) { build(:session) }

    it { expect { session.job_name_cache_key('job_name', { foo: 'bar' }) }.not_to raise_error }
  end

  describe '.was_job_scheduled?' do
    let(:session) { build(:session) }

    it { expect { session.was_job_scheduled?('job_name', { foo: 'bar' }) }.not_to raise_error }
  end

  describe '.job_scheduled!' do
    let(:session) { build(:session) }

    it { expect { session.job_scheduled!(job_name: 'job_name', job_id: 'foobar', args: { foo: 'bar' }) }.not_to raise_error }
  end
end
