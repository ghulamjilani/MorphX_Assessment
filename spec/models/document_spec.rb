# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Document, type: :model do
  # Class/Includes/Superclass
  it { expect(described_class.superclass).to be(ActiveRecord::Base) }

  # Constants
  describe 'Constants' do
    it { expect(Document::MAX_FILE_SIZE).to match(100 * 1024 * 1024) }

    it {
      expect(Document::AVAILABLE_CONTENT_TYPES).to match(%w[application/pdf])
    }
  end

  # Attributes / Nested Attributes
  describe 'Attributes' do
    let(:document) { FactoryBot.build(:document) }

    it { expect(document.attributes.keys).to include('id') }
    it { expect(document.attributes.keys).to include('title') }
    it { expect(document.attributes.keys).to include('description') }
    it { expect(document.attributes.keys).to include('hidden') }
    it { expect(document.attributes.keys).to include('channel_id') }
    it { expect(document.attributes.keys).to include('created_at') }
    it { expect(document.attributes.keys).to include('updated_at') }
  end

  # Associations
  describe 'Associations' do
    it { is_expected.to belong_to(:channel).required }
  end

  # Validations
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(1).is_at_most(256) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }

    describe 'validate_file!' do
      subject(:document) { FactoryBot.build(:document) }

      it 'valid' do
        expect(document).to be_valid
      end

      it 'file size is too large' do
        allow(document.file.blob).to receive(:byte_size).and_return(Document::MAX_FILE_SIZE + 1)
        expect(document).to be_invalid
        expect(document.errors.messages[:file]).to include(": #{document.title} - size is too large")
      end

      it 'file format is unsupported' do
        allow(document.file.blob).to receive(:content_type).and_return('qweasd')
        expect(document).to be_invalid
        expect(document.errors.messages[:file]).to include(": #{document.title} - type is unsupported")
      end

      it 'file is blank' do
        allow(document.file).to receive(:attached?).and_return(false)
        expect(document).to be_invalid
        expect(document.errors.messages[:file]).to include('is blank')
      end
    end
  end

  # Callbacks
  describe 'Callbacks' do
    describe 'after_save' do
      context 'when create' do
        it 'calls sync_title_with_blob_filename!' do
          document = FactoryBot.build(:document_with_own_title)
          allow(document).to receive(:sync_title_with_blob_filename!)
          document.save!
          expect(document).to have_received(:sync_title_with_blob_filename!).once
        end

        it 'does not call sync_title_with_blob_filename!' do
          document = FactoryBot.build(:document)
          allow(document).to receive(:sync_title_with_blob_filename!)
          document.save!
          expect(document).not_to have_received(:sync_title_with_blob_filename!)
        end
      end

      context 'when update' do
        before do
          @document = FactoryBot.create(:document)
        end

        it 'calls sync_title_with_blob_filename!' do
          @document.title = 'changed'
          allow(@document).to receive(:sync_title_with_blob_filename!)
          @document.save!
          expect(@document).to have_received(:sync_title_with_blob_filename!).once
        end

        it 'does not call sync_title_with_blob_filename!' do
          allow(@document).to receive(:sync_title_with_blob_filename!)
          expect(@document).not_to have_received(:sync_title_with_blob_filename!)
          @document.save!
        end
      end
    end
  end

  # Scopes
  describe 'Scopes' do
    describe '#includes_file' do
      before do
        FactoryBot.create_list(:document, 3)
      end

      it 'includes file_attachments' do
        documents = described_class.all.includes_file
        is_loaded_file_attachments = documents.map { |doc| doc.association(:file_attachment).loaded? }.uniq
        expect(is_loaded_file_attachments).to include(true)
        expect(is_loaded_file_attachments.length).to eq(1)
      end

      it 'includes file_attachments.blob' do
        documents = described_class.all.includes_file
        is_loaded_blobs = documents.map { |doc| doc.file_attachment.association(:blob).loaded? }.uniq
        expect(is_loaded_blobs).to include(true)
        expect(is_loaded_blobs.length).to eq(1)
      end
    end
  end

  # Class methods

  # Instance methods
  describe 'Instance methods' do
    describe 'title=' do
      context 'when pass "foo:bar.jpg"' do
        let(:title) { 'foo:bar.jpg' }

        it 'value is sanitized with ActiveStorage::Filename' do
          document = FactoryBot.build(:document, title: title)
          expect(document[:title]).to eq(ActiveStorage::Filename.new(title).to_s)
        end
      end

      context 'when pass "foo/bar.jpg"' do
        let(:title) { 'foo/bar.jpg' }

        it 'value is sanitized with ActiveStorage::Filename' do
          document = FactoryBot.build(:document, title: title)
          expect(document[:title]).to eq(ActiveStorage::Filename.new(title).to_s)
        end
      end

      context 'when pass nil' do
        let(:title) { nil }

        it 'set nil' do
          document = FactoryBot.build(:document, title: title)
          expect(document[:title]).to eq(nil)
        end
      end
    end

    describe 'title' do
      subject(:document) { FactoryBot.build(:document_with_own_title) }

      it { expect(document.title).to eq(document[:title]) }

      context 'when self[:title] is absent' do
        before { document.title = '' }

        context 'when file attached' do
          it { expect(document.title).to eq(document.file.blob.filename.base) }
        end

        context 'when file is blank' do
          it 'return blank title' do
            allow(document.file).to receive(:attached?).and_return(false)
            expect(document.title).to eq('')
          end
        end
      end
    end

    describe 'description' do
      it 'returns empty string when nil' do
        document = FactoryBot.build(:document, description: nil)
        expect(document.description).to eq('')
      end
    end

    # validate_file! tested on validations block

    describe 'sync_title_with_blob_filename!' do
      it 'when document is not saved' do
        document = FactoryBot.build(:document)
        document.send(:sync_title_with_blob_filename!)
        expect(document.file.blob.filename).to eq('test.pdf')
      end

      it 'when document is saved' do
        document = FactoryBot.create(:document, title: 'changed')
        document.send(:sync_title_with_blob_filename!)
        expect(document.file.blob.filename).to eq('changed.pdf')
      end
    end
  end
end
