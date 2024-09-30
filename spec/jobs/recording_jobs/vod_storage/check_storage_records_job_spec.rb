# frozen_string_literal: true

require 'spec_helper'

describe RecordingJobs::VodStorage::CheckStorageRecordsJob do
  let(:recording) { create(:recording_done) }

  it { expect { described_class.new.perform(recording.id) }.not_to raise_error }
end
