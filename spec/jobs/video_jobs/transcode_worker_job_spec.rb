# frozen_string_literal: true

require 'spec_helper'

describe VideoJobs::TranscodeWorkerJob do
  let(:video) { create(:video_downloaded, status: ::Video::Statuses::READY_TO_TR) }

  before do
    VCR.insert_cassette('qencode', record: :none)
  end

  it 'does not fail and updates status to transcoding' do
    expect do
      described_class.new.perform(video.id)
      video.reload
    end.to not_raise_error.and change(video, :status).to('transcoding')
  end

  context 'when transcode service is suspended' do
    before do
      VCR.eject_cassette
      VCR.insert_cassette('qencode_suspended', record: :none)
    end

    it 'does not raise error, reverts status to ready_to_tr and adds error reason' do
      expect do
        described_class.new.perform(video.id)
        video.reload
      end.to not_raise_error.and not_change(video, :status).and change(video, :error_reason).to('transcode_service_suspended')
    end
  end
end
