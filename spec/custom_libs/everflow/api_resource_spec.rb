# frozen_string_literal: true

require 'spec_helper'

describe Everflow::ApiResource do
  context 'when API Key provided' do
    before do
      Rails.application.credentials.backend[:initialize][:everflow][:enabled] = true
      Rails.application.credentials.backend[:initialize][:everflow][:api_key] = '4cecae998aa098473f5336a55753cead'
    end

    after do
      Rails.application.credentials.backend[:initialize][:everflow][:enabled] = false
      Rails.application.credentials.backend[:initialize][:everflow][:api_key] = nil
    end

    describe '#retrieve' do
      it { expect { described_class.retrieve(123) }.to raise_error(NotImplementedError) }
    end

    describe '#resource_path' do
      it { expect { described_class.send(:resource_path) }.to raise_error(NotImplementedError) }
    end

    describe '#headers' do
      it { expect(described_class.send(:headers)[:'x-eflow-api-key']).to eq('4cecae998aa098473f5336a55753cead') }
    end
  end

  context 'when no API Key provided' do
    describe '#headers' do
      it { expect { described_class.send(:headers) }.to raise_error('No API Key provided. Please add API Key in Config.') }
    end
  end
end
