# frozen_string_literal: true

require 'spec_helper'

describe Everflow::Network::Offer do
  let(:offer_id) { 1 } # do not change, VCR cassette contains status response for this transaction id

  before do
    Rails.application.credentials.backend[:initialize][:everflow][:enabled] = true
    Rails.application.credentials.backend[:initialize][:everflow][:api_key] = '4cecae998aa098473f5336a55753cead'
    VCR.insert_cassette('everflow_offer')
  end

  after do
    Rails.application.credentials.backend[:initialize][:everflow][:enabled] = false
    Rails.application.credentials.backend[:initialize][:everflow][:api_key] = nil
  end

  describe '#retrieve' do
    it { expect { described_class.retrieve(offer_id) }.not_to raise_error }
    it { expect(described_class.retrieve(offer_id)[:name]).to eq('development morphx business subscriptions') }
    it { expect { described_class.retrieve(123) }.to raise_error("Can't find entry in the database") }
  end
end
