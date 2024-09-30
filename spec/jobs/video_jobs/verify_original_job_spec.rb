# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe VideoJobs::VerifyOriginalJob do
  let(:video) { create(:video_downloaded) }
  let(:video_with_error) { create(:video_downloaded, error_reason: 'original_check_error_1') }

  before do
    video
    video_with_error
    resource = double
    bucket = double
    object = double
    allow(Aws::S3::Resource).to receive(:new).and_return(resource)
    allow(resource).to receive(:bucket).and_return(bucket)
    allow(bucket).to receive(:object).and_return(object)
    allow(object).to receive(:public_url).and_return("https://morphx-test-vod.s3.us-west-2.amazonaws.com#{video.hls_main}")
  end

  context 'when duration response successfull' do
    before do
      allow(Ffprobe).to receive(:get_duration).and_return('10.0')
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates video statuses' do
      expect do
        described_class.new.perform
        video.reload
        video_with_error.reload
      end.to change(video, :status).to(::Video::Statuses::ORIGINAL_VERIFIED).and change(video_with_error, :status).to(::Video::Statuses::ORIGINAL_VERIFIED).and change(video_with_error, :error_reason).to(nil)
    end
  end

  context 'when duration response failed' do
    before do
      allow(Ffprobe).to receive(:get_duration).and_return('')
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates video statuses' do
      expect do
        described_class.new.perform
        video.reload
        video_with_error.reload
      end.to not_change(video, :status).and change(video, :error_reason).to('original_check_error_1').and change(video_with_error, :status).to(::Video::Statuses::ERROR).and change(video_with_error, :error_reason).to('original_check_error_2')
    end
  end
end
