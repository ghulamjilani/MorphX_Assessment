# frozen_string_literal: true

require 'spec_helper'

describe Storage::RecordManagerFactory do
  describe '.create' do
    context 'when given storage record of object type "ActiveStorage::Attachment"' do
      let(:storage_record) { create(:storage_record_attachment) }

      it { expect { described_class.create(storage_record) }.not_to raise_error }

      it { expect(described_class.create(storage_record).class.name).to eq('Storage::RecordManager::Local::ActiveStorageAttachment') }
    end

    context 'when given storage record of object type "Aws::S3::ObjectSummary::Collection"' do
      let(:storage_record) { create(:storage_record_s3_collection) }

      it { expect { described_class.create(storage_record) }.not_to raise_error }

      it { expect(described_class.create(storage_record).class.name).to eq('Storage::RecordManager::S3::ObjectSummaryCollection') }
    end
  end
end
