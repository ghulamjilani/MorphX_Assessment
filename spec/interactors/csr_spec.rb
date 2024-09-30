# frozen_string_literal: true

require 'spec_helper'

describe Csr do
  describe '#issue_system_credit_refund' do
    let(:user) { create(:participant).user }
    let(:result) { described_class.new(user).issue_system_credit_refund(12.99) }

    before do
      result
    end

    it 'works' do
      expect(result).to be_kind_of(IssuedSystemCredit)
    end

    it { expect(LogTransaction.count).to eq(1) }
    it { expect { LogTransaction.last.as_html }.not_to raise_error }
  end
end
