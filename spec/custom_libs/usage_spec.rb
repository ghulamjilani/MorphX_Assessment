# frozen_string_literal: true

require 'spec_helper'

describe Usage do
  describe '.config' do
    it { expect { described_class.config }.not_to raise_error }
  end
end
