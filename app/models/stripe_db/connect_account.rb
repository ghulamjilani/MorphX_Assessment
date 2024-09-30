# frozen_string_literal: true
class StripeDb::ConnectAccount < ActiveRecord::Base
  belongs_to :user
  has_one :payout_method, class_name: 'PayoutMethod', foreign_key: :pid, primary_key: :account_id, inverse_of: :connect_account
  has_many :bank_accounts, class_name: 'StripeDb::ConnectBankAccount', foreign_key: :stripe_account_id, primary_key: :account_id, inverse_of: :connect_account

  def stripe_item
    @stripe_item ||= Stripe::Account.retrieve(account_id)
  rescue StandardError
    nil
  end
end
