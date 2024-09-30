# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Shared::Transcodable do
  let(:percent) { 75 }
  let(:transcode_task) { create(:transcode_task, percent: percent) }
  let(:transcodable) { transcode_task.transcodable }

  describe '#transcode_task_percent' do
    it { expect { transcodable.transcode_task_percent }.not_to raise_error }

    it { expect(transcodable.transcode_task_percent).to eq(percent) }
  end
end
