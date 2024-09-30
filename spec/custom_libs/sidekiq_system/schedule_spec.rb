# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.disable! do
  describe SidekiqSystem::Schedule do
    let(:job_klass) { Testing::SleepJob }
    let(:arg) { 30 }
    let(:wrong_arg) { 40 }

    before do
      Sidekiq::Testing.disable!
    end

    after do
      Sidekiq::ScheduledSet.new.clear
      Sidekiq::Testing.fake!
    end

    describe '.exists?' do
      context 'when job scheduled with arg' do
        before do
          job_klass.perform_at(20.seconds.from_now, arg)
        end

        it { expect { described_class.exists?(job_klass, arg) }.not_to raise_error }

        it { expect { described_class.exists?(job_klass) }.not_to raise_error }

        it { expect(described_class).to be_exists(job_klass, arg) }

        it { expect(described_class).not_to be_exists(job_klass) }

        it { expect(described_class).not_to be_exists(job_klass, wrong_arg) }
      end

      context 'when job scheduled with no arg' do
        before do
          job_klass.perform_at(20.seconds.from_now)
        end

        it { expect { described_class.exists?(job_klass) }.not_to raise_error }

        it { expect { described_class.exists?(job_klass, wrong_arg) }.not_to raise_error }

        it { expect(described_class).to be_exists(job_klass) }

        it { expect(described_class).not_to be_exists(job_klass, wrong_arg) }
      end

      context 'when job not scheduled' do
        it 'does not raise error' do
          expect { described_class.exists?(job_klass, arg) }.not_to raise_error
        end

        it 'works properly' do
          expect(described_class).not_to be_exists(job_klass, arg)
        end
      end

      context 'when job enqueued with arg' do
        before do
          job_klass.perform_at(5.minutes.from_now, arg)
        end

        it { expect { described_class.exists?(job_klass, arg) }.not_to raise_error }

        it { expect { described_class.exists?(job_klass) }.not_to raise_error }

        it { expect(described_class).to be_exists(job_klass, arg) }

        it { expect(described_class).not_to be_exists(job_klass) }

        it { expect(described_class).not_to be_exists(job_klass, wrong_arg) }
      end

      context 'when job enqueued with no arg' do
        before do
          job_klass.perform_at(5.minutes.from_now)
        end

        it { expect { described_class.exists?(job_klass) }.not_to raise_error }

        it { expect { described_class.exists?(job_klass, wrong_arg) }.not_to raise_error }

        it { expect(described_class).to be_exists(job_klass) }

        it { expect(described_class).not_to be_exists(job_klass, wrong_arg) }
      end
    end

    describe '.find' do
      before do
        job_klass.perform_at(20.seconds.from_now, arg)
      end

      it { expect { described_class.find(job_klass, arg) }.not_to raise_error }

      it { expect(described_class.find(job_klass, arg)).to be_present }
    end

    describe '.remove' do
      before do
        job_klass.perform_at(5.minutes.from_now, arg)
      end

      it { expect { described_class.remove(job_klass, arg) }.not_to raise_error }

      it 'removes scheduled job' do
        described_class.remove(job_klass, arg)
        expect(described_class).not_to be_exists(job_klass, arg)
      end
    end

    describe 'wrapped jobs' do
      let(:id) { rand 999 }

      before do
        ActiveJob::Base.queue_adapter = :sidekiq
        FreeSubscriptionsMailer.going_to_be_finished(id).deliver_later(wait_until: 1.week.from_now)
      end

      after do
        ActiveJob::Base.queue_adapter = :test
      end

      describe '.find_wrapped' do
        it { expect { described_class.find_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', id) }.not_to raise_error }

        it { expect(described_class.find_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', id)).to be_present }
      end

      describe '.remove_wrapped' do
        it { expect { described_class.remove_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', id) }.not_to raise_error }

        it 'removes scheduled job' do
          described_class.remove_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', id)
          expect(described_class.find_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', id)).to be_blank
        end
      end
    end
  end
end
