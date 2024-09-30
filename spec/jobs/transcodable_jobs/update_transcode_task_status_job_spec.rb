# frozen_string_literal: true

require 'spec_helper'

describe TranscodableJobs::UpdateTranscodeTaskStatusJob do
  let(:transcode_task) { create(:transcode_task_encoding) }
  let(:job_id) { transcode_task.job_id }
  let(:transcodable) do
    transcodable = transcode_task.transcodable
    transcodable.update_columns(status: :transcoding)
    transcodable
  end
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

  it { expect { described_class.new.perform(transcode_task.id) }.not_to raise_error }

  it 'updates transcode task' do
    expect do
      described_class.new.perform(transcode_task.id)
      transcodable.reload
      transcode_task.reload
    end.to change(transcode_task, :status).and change(transcode_task, :percent).and change(transcodable, :status).to('transcoded')
  end
end