# frozen_string_literal: true
class StripeDb::ConnectBankAccount < ActiveRecord::Base
  belongs_to :connect_account, class_name: 'StripeDb::ConnectAccount', foreign_key: :stripe_account_id, primary_key: :account_id

  def self.create_or_update_from_stripe(account_id, sid)
    response = Stripe::Account.retrieve_external_account(account_id, sid)
    object = find_or_initialize_by(stripe_id: response.id)
    object.stripe_id = response.id
    object.stripe_account_id = response.account
    object.account_holder_name = response.account_holder_name
    object.account_holder_type = response.account_holder_type
    object.bank_name = response.bank_name
    object.country = response.country
    object.currency = response.currency
    object.default_for_currency = begin
      response.default_for_currency
    rescue StandardError
      false
    end
    object.fingerprint = response.fingerprint
    object.last4 = response.last4
    object.routing_number = response.routing_number
    object.status = response.status
    object.save
    object
  end

  def stripe_item
    @stripe_item ||= Stripe::Account.retrieve_external_account(stripe_account_id, stripe_id)
  end
end
