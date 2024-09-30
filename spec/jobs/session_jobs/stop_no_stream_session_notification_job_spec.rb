# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::StopNoStreamSessionNotificationJob do
  let(:session) { create(:livestream_session) }
  let(:client) { instance_double(Sender::Ffmpegservice) }

  before do
    # allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
    # allow(client).to receive(:stats_transcoder).and_return({ connected: { value: 'No' } })
    allow(SidekiqSystem::Schedule).to receive(:exists?).and_return(true)
  end

  after do
    Sidekiq::ScheduledSet.new.clear
  end

  it { expect { described_class.new.perform(session.id) }.not_to raise_error }

  it 'enqueues email delivery job' do
    described_class.new.perform(session.id)
    expect(ActionMailer::MailDeliveryJob).to(
      have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                              args: [a_hash_including(to: session.presenter.user.email, subject: 'Your session will be stopped in 5 minutes')])
    )
  end
end
