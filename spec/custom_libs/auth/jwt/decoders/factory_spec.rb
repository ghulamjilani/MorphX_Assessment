# frozen_string_literal: true

require 'spec_helper'

describe Auth::Jwt::Decoders::Factory do
  describe '#model_decoder_by_type' do
    types = Auth::Jwt::Types::ALL - [Auth::Jwt::Types::USAGE]
    types.each do |type|
      context "when given type '#{type}'" do
        it { expect { described_class.model_decoder_by_type(type) }.not_to raise_error }

        it { expect(described_class.model_decoder_by_type(type)).to be_truthy }
      end
    end
  end
end
