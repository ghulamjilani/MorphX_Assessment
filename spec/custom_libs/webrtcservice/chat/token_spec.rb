# frozen_string_literal: true

require 'spec_helper'

describe Webrtcservice::Chat::Token do
  let(:subject1) { described_class }

  describe '.access_token' do
    it { expect { subject1.access_token(rand(999)) }.not_to raise_error }
    it { expect(subject1.access_token(rand(999))).to be_truthy }
  end
end
