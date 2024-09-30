# frozen_string_literal: true

require 'spec_helper'

describe Storage::RecordManager::Local::ActiveStorageAttachment do
  let(:storage_record_attachment) { create(:storage_record_attachment) }

  describe 'instance methods' do
    let(:instance) { described_class.new(storage_record_attachment) }

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
