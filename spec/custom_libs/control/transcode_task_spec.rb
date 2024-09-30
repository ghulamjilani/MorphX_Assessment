# frozen_string_literal: true

require 'spec_helper'

describe Control::TranscodeTask do
  let(:transcode_task) { create(:transcode_task_encoding) }
  let(:control) { described_class.new(transcode_task) }

  describe '#update_status' do
    let(:response_body) do
      { statuses:
        { transcode_task.job_id =>
          {
            status: 'completed',
            percent: 100,
            error: 0,
            error_description: nil
          } },
        error: 0 }.to_json
    end

    before do
      stub_request(:any, %r{^https://api.qencode.com/v1/status})
        .to_return(status: 200, body: response_body, headers: {})
    end

    it { expect { control.update_status }.not_to raise_error }

    it 'updates transcode task' do
      expect do
        control.update_status
        transcode_task.reload
      end.to change(transcode_task, :status).and change(transcode_task, :percent)
    end
  end
end
