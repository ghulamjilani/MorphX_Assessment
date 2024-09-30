# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe RecordingJobs::TranscodeSchedulerJob do
  let(:recording) { create(:recording, status: :ready_to_tr) }

  before do
    VCR.insert_cassette('qencode', record: :none)
    recording
  end

  it { expect { described_class.new.perform }.not_to raise_error }

  it 'works' do
    expect do
      Sidekiq::Testing.inline! { described_class.new.perform }
      recording.reload
    end.to change(recording, :status).to('transcoding')
  end
end
