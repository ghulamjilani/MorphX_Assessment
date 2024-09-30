# frozen_string_literal: true

require 'spec_helper'

describe BraintreeRefundCoefficient do
  subject { described_class.new(session).coefficient }

  context 'when session starts in 3 hours from now' do
    let(:session) { Session.new(start_at: 3.hours.from_now) }

    it { is_expected.to eq(0) }
  end

  context 'when session starts in 5 hours' do
    let(:session) { Session.new(start_at: 5.hours.from_now) }

    it { is_expected.to eq(0.5) }
  end

  context 'when session starts in 13 hours from now' do
    it 'allows full sys credit or money refund' do
      session = Session.new(start_at: 13.hours.from_now)

      expect(described_class.new(session)).to be_could_be_full_refund_in_original_payment_type
    end
  end
end
