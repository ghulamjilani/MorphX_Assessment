# frozen_string_literal: true

require 'spec_helper'

describe Auth::Jwt::Encoders::Factory do
  describe '#model_encoder_by_type' do
    Auth::Jwt::Types::ALL.each do |type|
      context "when given type '#{type}'" do
        it { expect { described_class.model_encoder_by_type(type) }.not_to raise_error }

        it { expect(described_class.model_encoder_by_type(type)).to be_truthy }
      end
    end
  end
end
