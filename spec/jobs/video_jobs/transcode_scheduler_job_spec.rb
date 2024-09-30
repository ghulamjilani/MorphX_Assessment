# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe VideoJobs::TranscodeSchedulerJob do
  let(:video) { create(:video, status: :ready_to_tr) }

  before do
    VCR.insert_cassette('qencode', record: :none)
    video
  end

  it { expect { described_class.new.perform }.not_to raise_error }

  it 'works' do
    expect do
      Sidekiq::Testing.inline! { described_class.new.perform }
      video.reload
    end.to change(video, :status).to('transcoding')
  end
end
