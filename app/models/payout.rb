# frozen_string_literal: true
class Payout < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  has_many :payment_transactions

  enum provider: {
    stripe: 0
  }
  enum status: {
    pending: 0,
    paid: 1,
    failed: 2,
    outdated: 3
  }
end
