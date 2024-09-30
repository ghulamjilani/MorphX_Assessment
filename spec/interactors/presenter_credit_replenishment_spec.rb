# frozen_string_literal: true

require 'spec_helper'

describe PresenterCreditReplenishment do
  it 'works' do
    # TODO: - need to find a way to mock braintree interface
    skip 'skip temporary'

    # user = create(:user_with_credit_card)
    # expect(BraintreeTransaction.count).to eq(0)
    #
    # expect(user.system_credit_balance).to eq(0.0)
    #
    # interactor = described_class.new(user, 11.1)
    # expect(interactor.execute).to be true
    #
    # expect(interactor.success_message).not_to be_blank
    # expect(interactor.error_message).to be_blank
    #
    # expect(BraintreeTransaction.count).to eq(1)
    # expect(LogTransaction.count).to eq(1)
    # expect(user.reload.system_credit_balance).to eq(11.1)
    # expect { LogTransaction.last.as_html }.not_to raise_error
  end
end
