# frozen_string_literal: true

require 'spec_helper'

describe Everflow::Network::Transaction do
  let(:transaction_id) { '78856b3d27584583a7f56f23a1959cea' } # do not change, VCR cassette contains status response for this transaction id

  before do
    Rails.application.credentials.backend[:initialize][:everflow][:enabled] = true
    Rails.application.credentials.backend[:initialize][:everflow][:api_key] = '4cecae998aa098473f5336a55753cead'
    VCR.insert_cassette('everflow_transaction')
  end

  after do
    Rails.application.credentials.backend[:initialize][:everflow][:enabled] = false
    Rails.application.credentials.backend[:initialize][:everflow][:api_key] = nil
  end

  describe '#retrieve' do
    it { expect { described_class.retrieve(transaction_id) }.not_to raise_error }
    it { expect(described_class.retrieve(transaction_id)[:click][:transaction_id]).to eq(transaction_id) }
    it { expect { described_class.retrieve(123) }.to raise_error('No click associated to that transaction id found') }
  end
end
