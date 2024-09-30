# frozen_string_literal: true
require 'spec_helper'

describe Partner::Plan do
  let(:partner_plan) { create(:partner_plan) }

  describe '.scopes' do
    before do
      partner_plan
    end

    describe '.enabled' do
      it { expect { described_class.enabled }.not_to raise_error }
    end
  end
end
