# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::ActiveStorage::Attachment::Extensions do
  let(:model) { create(:recording) }

  describe '#callbacks' do
    describe '#create_storage_record' do
      before { model }

      it { expect(::Storage::Record.where(model: model, relation_type: :file)).to be_exist }
    end
  end
end
