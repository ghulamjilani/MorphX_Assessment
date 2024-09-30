# frozen_string_literal: true
require 'spec_helper'

describe Storage::Record do
  let(:storage_record) { create(:storage_record_attachment) }

  describe '#refresh_object_size' do
    it { expect { storage_record.refresh_object_size }.not_to raise_error }

    it { expect { storage_record.refresh_object_size }.to change(StorageJobs::RefreshObjectSizeJob.jobs, :size) }
  end

  describe '#object' do
    context 'when storage record is for ActiveStorage::Attachment' do
      it { expect(storage_record.model.file.attachment).to be_persisted }
      it { expect { storage_record.object }.not_to raise_error }

      it { expect(storage_record.object).to be_present }
    end
  end

  describe '#blob_exists?' do
    it { expect { storage_record.blob_exists? }.not_to raise_error }

    it { expect(storage_record).to be_blob_exists }
  end

  describe '#manager' do
    it { expect { storage_record.manager }.not_to raise_error }

    it { expect(storage_record.manager).to be_present }
  end

  describe '#increment_usage' do
    let(:byte_size) { storage_record.byte_size + 100 }

    it { expect { storage_record.update(byte_size:) }.not_to raise_error }

    it { expect { storage_record.update(byte_size:) }.to change(FeatureHistoryUsage, :count).by(1) }
  end

  describe '#decrement_usage' do
    let(:byte_size) { storage_record.byte_size + 100 }

    it { expect { storage_record.send(:decrement_usage) }.not_to raise_error }

    it { expect { storage_record.send(:decrement_usage) }.to change(FeatureHistoryUsage, :count).by(1) }
  end
end
