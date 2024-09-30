# frozen_string_literal: true
class Affiliate::Everflow::TrackedPayment < Affiliate::Everflow::ApplicationRecord
  PURCHASED_ITEM_TYPES = %w[StripeDb::ServiceSubscription StripeDb::Subscription].freeze

  belongs_to :payment_transaction
  belongs_to :purchased_item, polymorphic: true
  belongs_to :affiliate_everflow_transaction, class_name: 'Affiliate::Everflow::Transaction'
end
