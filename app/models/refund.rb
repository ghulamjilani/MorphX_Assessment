# frozen_string_literal: true
class Refund < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :payment_transaction

  validates :pid, :provider, presence: true

  enum provider: {
    stripe: 0,
    paypal: 1
  }
end
