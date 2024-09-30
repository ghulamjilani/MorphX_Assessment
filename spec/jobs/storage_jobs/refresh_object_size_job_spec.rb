# frozen_string_literal: true

require 'spec_helper'

describe StorageJobs::RefreshObjectSizeJob do
  context 'when given local attachment' do
    let(:storage_record) { create(:storage_record_attachment) }

    it { expect { described_class.new.perform(storage_record.id) }.not_to raise_error }
  end

  context 'when given s3 collection' do
    let(:storage_record) { create(:storage_record_s3_collection) }

    it { expect { described_class.new.perform(storage_record.id) }.not_to raise_error }
  end
end
