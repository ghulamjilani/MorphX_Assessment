# frozen_string_literal: true
require 'spec_helper'

describe Im::Message do
  let(:im_message) { create(:im_message) }
  let(:im_message_deleted) { create(:im_message, deleted_at: Time.now.utc) }

  describe 'validations' do
    let(:im_message) { build(:im_message, conversation: nil, conversation_participant: nil, body: '*' * 1000) }

    before do
      im_message.validate
    end

    it { expect(im_message.errors.attribute_names).to include(:conversation) }

    it { expect(im_message.errors.attribute_names).to include(:conversation_participant) }

    it { expect(im_message.errors.attribute_names).to include(:body) }

    context 'when body is too long' do
      let(:im_message) { build(:im_message, body: Forgery(:lorem_ipsum).words(600)) }

      it { expect(im_message.errors.attribute_names).to include(:body) }
    end
  end

  describe '.scopes' do
    describe '.not_deleted' do
      before do
        im_message
        im_message_deleted
      end

      it { expect(described_class.not_deleted.where(id: im_message.id)).to exist }

      it { expect(described_class.not_deleted.where(id: im_message_deleted.id)).not_to exist }
    end

    describe '.deleted' do
      before do
        im_message
        im_message_deleted
      end

      it { expect(described_class.deleted.where(id: im_message_deleted.id)).to exist }

      it { expect(described_class.deleted.where(id: im_message.id)).not_to exist }
    end
  end

  describe 'Instance methods' do
    describe '#deleted?' do
      let(:im_message) { build(:im_message) }
      let(:im_message_deleted) { build(:im_message, deleted_at: Time.now.utc) }

      it { expect { im_message.deleted? }.not_to raise_error }

      it { expect(im_message).not_to be_deleted }

      it { expect(im_message_deleted).to be_deleted }
    end

    describe '#deleted!' do
      let(:im_message) { build(:im_message) }

      it { expect { im_message.deleted! }.not_to raise_error }

      it { expect { im_message.deleted! }.to change(im_message, :deleted_at) }
    end

    describe '#restore!' do
      let(:im_message_deleted) { build(:im_message, deleted_at: Time.now.utc) }

      it { expect { im_message_deleted.restore! }.not_to raise_error }

      it { expect { im_message_deleted.restore! }.to change(im_message_deleted, :deleted_at).to(nil) }
    end

    describe '.notify_conversation_new_message' do
      it { expect { im_message.send(:notify_conversation_new_message) }.not_to raise_error }
    end

    describe '.notify_conversation_message_updated' do
      it { expect { im_message.send(:notify_conversation_message_updated) }.not_to raise_error }
    end

    describe '.notify_conversation_message_deleted' do
      it { expect { im_message.send(:notify_conversation_message_deleted) }.not_to raise_error }
    end

    describe '.sanitize_body' do
      it { expect { im_message.send(:sanitize_body) }.not_to raise_error }
    end
  end
end
