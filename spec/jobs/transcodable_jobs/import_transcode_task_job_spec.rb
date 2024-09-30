# frozen_string_literal: true

require 'spec_helper'

describe TranscodableJobs::ImportTranscodeTaskJob do
  let(:transcodable) { create(:video_transcoded, status: ::Video::Statuses::TRANSCODING) }
  let(:job_id) { SecureRandom.hex(16) }
  let(:response_body) do
    { statuses:
      { job_id =>
        {
          status: 'completed',
          percent: 100,
          error: 0,
          error_description: nil
        } },
      error: 0 }.to_json
  end

  before do
    transcodable

    stub_request(:any, %r{^https://api.qencode.com/v1/status}).to_return(status: 200, body: response_body, headers: {})
  end

  it { expect { described_class.new.perform(job_id, transcodable.id, transcodable.class.name) }.not_to raise_error }

  it 'updates transcode task' do
    expect do
      described_class.new.perform(job_id, transcodable.id, transcodable.class.name)
      transcodable.reload
    end.to change(TranscodeTask, :count).and change(transcodable, :status).to('transcoded')
  end
end
