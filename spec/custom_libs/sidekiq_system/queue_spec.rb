# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.disable! do
  describe SidekiqSystem::Queue do
    let(:job_klass) { Testing::SleepJob }
    let(:arg) { 30 }
    let(:wrong_arg) { 40 }

    before do
      Sidekiq::Testing.disable!
    end

    after do
      Sidekiq::ScheduledSet.new.clear
      described_class.queues.each(&:clear)
      Sidekiq::Testing.fake!
    end

    describe '.exists?' do
      before do
        described_class.queues.each(&:clear)
        job_klass.perform_async(arg)
      end

      it { expect { described_class.exists?(job_klass, arg) }.not_to raise_error }

      it { expect(described_class).to be_exists(job_klass, arg) }
    end

    describe '.find' do
      before do
        described_class.queues.each(&:clear)
        job_klass.perform_async(arg)
      end

      it { expect { described_class.find(job_klass, arg) }.not_to raise_error }

      it { expect(described_class.find(job_klass, arg)).to be_present }
    end

    describe '.remove' do
      before do
        described_class.queues.each(&:clear)
        job_klass.perform_async(arg)
      end

      it { expect { described_class.remove(job_klass, arg) }.not_to raise_error }

      it 'removes enqueued job' do
        described_class.remove(job_klass, arg)
        expect(described_class).not_to be_exists(job_klass, arg)
      end
    end
  end
end
