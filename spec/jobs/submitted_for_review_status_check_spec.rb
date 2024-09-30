# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SubmittedForReviewStatusCheck do
  let(:channel) { create(:channel) }

  it { expect(channel.draft?).to eq(true) }

  it 'works' do
    mailer = double
    allow(mailer).to receive(:deliver_later)
    allow(ChannelMailer).to receive(:draft_channel_reminder).once.with(channel.id).and_return(mailer)
    Sidekiq::Testing.inline! { described_class.perform_async(channel.id) }
  end
end
