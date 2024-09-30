# frozen_string_literal: true

require 'spec_helper'

describe VideoJobs::VodStorage::CheckStorageRecordsJob do
  let(:video) { create(:seed_video) }

  it { expect { described_class.new.perform(video.id) }.not_to raise_error }
end
