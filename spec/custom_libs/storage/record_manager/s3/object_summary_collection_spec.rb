# frozen_string_literal: true

require 'spec_helper'

describe Storage::RecordManager::S3::ObjectSummaryCollection do
  let(:storage_record) { create(:storage_record_s3_collection) }

  describe 'instance methods' do
    let(:instance) { described_class.new(storage_record) }

    describe '#object_byte_size' do
      it { expect { instance.object_byte_size }.not_to raise_error }

      it { expect(instance.object_byte_size).not_to be_nil }
    end

    describe '#object_exists?' do
      it { expect { instance.object_exists? }.not_to raise_error }
    end

    describe '#remove_object' do
      it { expect { instance.remove_object }.not_to raise_error }
    end

    describe '#refresh_object_size' do
      it { expect { instance.refresh_object_size }.not_to raise_error }
    end

    describe '#refresh_record' do
      it { expect { instance.refresh_record }.not_to raise_error }
    end
  end
end
