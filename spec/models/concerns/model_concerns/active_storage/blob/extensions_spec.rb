# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::ActiveStorage::Blob::Extensions do
  let(:model) { create(:recording) }

  describe '#callbacks' do
    describe '#destroy_storage_record' do
      context 'when model is not destroyed' do
        it { expect(::Storage::Record.where(model: model, relation_type: :file)).to be_exist }
      end

      context 'when model is destroyed' do
        before { model.destroy }

        it { expect(::Storage::Record.where(model: model, relation_type: :file)).not_to be_exist }
      end
    end
  end
end
