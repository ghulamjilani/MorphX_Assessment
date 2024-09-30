# frozen_string_literal: true

require 'spec_helper'

describe Auth::WebsocketToken do
  let(:abstract_user) { create(%i[user guest].sample) }
  let(:visitor_id) { SecureRandom.uuid }
  let(:websocket_token) { described_class.new(abstract_user:, visitor_id:) }

  describe '.cache_key' do
    it { expect { described_class.cache_key(visitor_id) }.not_to raise_error }

    it { expect(described_class.cache_key(visitor_id)).to be_present }
  end

  describe '.create' do
    it { expect { described_class.create(visitor_id:, abstract_user:) }.not_to raise_error }

    it { expect(described_class.create(visitor_id:, abstract_user:)).to be_present }
  end

  describe '.find' do
    let(:websocket_token) { described_class.create(abstract_user:, visitor_id:) }

    it { expect { described_class.find(websocket_token.id) }.not_to raise_error }

    it { expect(described_class.find(websocket_token.id)).to be_present }
  end

  describe '#cache_key' do
    it { expect { websocket_token.cache_key }.not_to raise_error }

    it { expect(websocket_token.cache_key).to be_present }
  end

  describe '#save' do
    it { expect { websocket_token.save }.not_to raise_error }

    it { expect(websocket_token.save).to be_present }
  end

  describe '#payload' do
    it { expect { websocket_token.payload }.not_to raise_error }

    it { expect(websocket_token.payload).to be_present }
  end
end
