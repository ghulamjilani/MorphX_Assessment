# frozen_string_literal: true

require 'spec_helper'

describe RecordingJobs::TranscodeWorkerJob do
  let(:recording) { create(:recording, status: :ready_to_tr) }

  before do
    VCR.insert_cassette('qencode', record: :none)
    recording
  end

  it 'does not fail and updates status to transcoding' do
    expect do
      described_class.new.perform(recording.id)
      recording.reload
    end.to not_raise_error.and change(recording, :status).to('transcoding')
  end

  context 'when transcode service is suspended' do
    before do
      VCR.eject_cassette
      VCR.insert_cassette('qencode_suspended', record: :none)
    end

    it 'does not raise error, reverts status to ready_to_tr and adds error reason' do
      expect do
        described_class.new.perform(recording.id)
        recording.reload
      end.to not_raise_error.and not_change(recording, :status).and change(recording, :error_reason).to('transcode_service_suspended')
    end
  end
end
