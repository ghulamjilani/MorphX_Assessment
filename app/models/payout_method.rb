# frozen_string_literal: true
class PayoutMethod < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :user
  belongs_to :connect_account, class_name: 'StripeDb::ConnectAccount', foreign_key: :pid, primary_key: :account_id, inverse_of: :payout_method
  has_one :payout_identity

  enum business_type: {
    individual: 0,
    company: 1
  }
  enum provider: {
    stripe: 0,
    paypal: 1,
    payoneer: 2
  }
  enum status: {
    draft: 0,
    done: 1,
    rejected: 2
  }
  def payout_method
    case provider
    when 'stripe'
      'Bank Account'
    when 'paypal'
      'PayPal'
    when 'payoneer'
      'Payoneer'
    end
  end

  def info
    case provider
    when 'stripe'
      sa = Stripe::Account.retrieve(pid)
      bank_account = sa.external_accounts.detect(&:default_for_currency?)
      "*****#{bank_account&.last4}"
    when 'paypal'
      pid
    when 'payoneer'
      'Payoneer'
    end
  end
end
