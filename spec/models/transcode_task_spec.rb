# frozen_string_literal: true
require 'spec_helper'

describe TranscodeTask do
  let(:transcode_task) { build(:transcode_task, transcodable: nil) }

  describe '#task_params' do
    it { expect { transcode_task.task_params }.not_to raise_error }
  end

  describe '#completed?' do
    it { expect { transcode_task.completed? }.not_to raise_error }

    context 'when completed' do
      let(:transcode_task) { build(:transcode_task, transcodable: nil, status: :completed) }

      it { expect(transcode_task).to be_completed }
    end

    context 'when not completed' do
      let(:transcode_task) { build(:transcode_task, transcodable: nil, status: :encoding) }

      it { expect(transcode_task).not_to be_completed }
    end
  end
end
