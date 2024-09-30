# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.disable! do
  describe SidekiqSystem::Workers do
    let(:job_klass) { Testing::SleepJob }
    let(:arg) { 30 }
    let(:wrong_arg) { 40 }

    before do
      Sidekiq::Testing.disable!
    end

    after do
      Sidekiq::ScheduledSet.new.clear
      SidekiqSystem::Queue.queues.each(&:clear)
      Sidekiq::Testing.fake!
    end

    describe '.job_running?' do
      before do
        job_klass.perform_async(arg)
      end

      it { expect { described_class.job_running?(job_klass, arg) }.not_to raise_error }

      it { expect(described_class).not_to be_job_running(job_klass, arg) }
    end
  end
end
