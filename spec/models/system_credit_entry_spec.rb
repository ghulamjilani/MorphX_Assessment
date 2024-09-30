# frozen_string_literal: true
require 'spec_helper'

describe SystemCreditEntry do
  describe '#system_credit_refund!(amount' do
    it 'does not fail' do
      obj = create(:system_credit_entry)

      obj.system_credit_refund!(obj.amount)
    end
  end
end
