# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe RecordingJobs::VerifyTranscodedJob do
  let(:recording) { create(:recording_transcoded) }
  let(:recording_with_error) { create(:recording_transcoded, error_reason: 'transcoded_check_error_1') }

  before do
    recording
    recording_with_error
    resource = double
    bucket = double
    object = double
    allow(Aws::S3::Resource).to receive(:new).and_return(resource)
    allow(resource).to receive(:bucket).and_return(bucket)
    allow(bucket).to receive(:object).and_return(object)
    allow(object).to receive(:public_url).and_return("https://morphx-test-vod.s3.us-west-2.amazonaws.com#{recording.hls_main}")
  end

  context 'when duration response successfull' do
    before do
      allow(Ffprobe).to receive(:get_duration).and_return('10.0')
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates recording statuses' do
      expect do
        described_class.new.perform
        recording.reload
        recording_with_error.reload
      end.to change(recording, :status).to('done').and change(recording_with_error, :status).to('done').and change(recording_with_error, :error_reason).to(nil)
    end
  end

  context 'when duration response failed' do
    before do
      allow(Ffprobe).to receive(:get_duration).and_return('')
    end

    it { expect { described_class.new.perform }.not_to raise_error }

    it 'updates recording statuses' do
      expect do
        described_class.new.perform
        recording.reload
        recording_with_error.reload
      end.to not_change(recording, :status).and change(recording, :error_reason).to('transcoded_check_error_1').and change(recording_with_error, :status).to('error').and change(recording_with_error, :error_reason).to('transcoded_check_error_2')
    end
  end
end
