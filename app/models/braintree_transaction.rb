# frozen_string_literal: true
class BraintreeTransaction < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # disable STI
  self.inheritance_column = :_type_disabled

  belongs_to :paid_by_organizer_user, class_name: 'User'
  belongs_to :abstract_session, polymorphic: true, touch: true
  belongs_to :user
  belongs_to :pending_refund

  scope :submitted_for_settlement, -> { where('status = ?', Statuses::SUBMITTED_FOR_SETTLEMENT) }
  scope :authorized, -> { where('status = ?', Statuses::AUTHORIZED) }
  scope :unauthorized, -> { where('status = ?', Statuses::UNAUTHORIZED) }

  scope :not_voided, -> { where.not(status: Statuses::VOIDED) }

  scope :immersive_access,  -> { where('type = ?', TransactionTypes::IMMERSIVE) }
  scope :livestream_access, -> { where('type = ?', TransactionTypes::LIVESTREAM) }
  scope :vod_access,        -> { where('type = ?', TransactionTypes::RECORDED) }
  scope :recording_access,  -> { where('type = ?', TransactionTypes::RECORDING) }

  scope :live_access,      -> { where(type: [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]) }

  scope :replenishment, -> { where('type = ?', TransactionTypes::REPLENISHMENT) }

  module Statuses
    # Credit cards
    SUBMITTED_FOR_SETTLEMENT = 'submitted_for_settlement'
    AUTHORIZED               = 'authorized'
    UNAUTHORIZED             = 'unauthorized'
    VOIDED                   = 'voided'
    SETTLED                  = 'settled'

    # Paypal
    SETTLING                 = 'settling'
    # TODO-low - fill missing statuses

    ALL = [
      SUBMITTED_FOR_SETTLEMENT,
      AUTHORIZED,
      UNAUTHORIZED,
      VOIDED,
      SETTLED,

      SETTLING
    ].freeze
  end

  module PaymentInstrumentTypes
    CREDIT_CARD    = 'credit_card'
    PAYPAL_ACCOUNT = 'paypal_account'
  end

  validates :status, inclusion: { in: Statuses::ALL }

  validates :type, inclusion: { in: ::TransactionTypes::ALL }

  validates :abstract_session, presence: true, if: lambda { |bt|
                                                     bt.type == TransactionTypes::IMMERSIVE || bt.type == TransactionTypes::LIVESTREAM || bt.type == TransactionTypes::RECORDED
                                                   }

  # because state_machine is abandoned and with Rails 4.2 :initial option is simply ignored
  after_initialize :set_initial_status
  before_validation :set_checked_at, if: :status_changed?

  after_destroy do
    PendingRefund.where(braintree_transaction: self).map(&:destroy)
  end

  def set_initial_status
    self.status ||= :unauthorized
  end

  state_machine :status, initial: :unauthorized do
    event :authorize do
      transition [:unauthorized] => :authorized
    end

    event :submit_for_settlement do
      transition [:authorized] => :submitted_for_settlement
    end

    event :settle do
      transition [:submitted_for_settlement] => :settled
    end

    event :void do
      transition %i[authorized submitted_for_settlement] => :voided
    end
  end

  def image_url
    if credit_card?
      "https://assets.braintreegateway.com/payment_method_logo/#{card_type.downcase}.png?environment=#{Braintree::Configuration.environment}"
    elsif paypal?
      "https://assets.braintreegateway.com/payment_method_logo/paypal.png?environment=#{Braintree::Configuration.environment}"
    else
      raise ArgumentError, "can not interpret #{inspect}"
    end
  end

  def credit_card?
    credit_card_last_4.present?
  end

  def paypal?
    paypal_payer_email.present?
  end

  def receipt_title
    credit_card? ? 'Authorization Code' : 'PayPal Email'
  end

  def receipt_value
    credit_card? ? processor_authorization_code : paypal_payer_email
  end

  def system_credit_refund!(refund_amount)
    credit_was = user.system_credit_balance

    user.receive_issued_system_credit!(amount: refund_amount,
                                       type: IssuedSystemCredit::Types::CHOSEN_REFUND,
                                       status: IssuedSystemCredit::Statuses::OPEN)

    entry = Plutus::Entry.new(
      description: "System credit refund - #{abstract_session.always_present_title}",
      commercial_document: self,
      debits: [
        { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: refund_amount }
      ],
      credits: [
        { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: refund_amount }
      ]
    )
    entry.save!

    user.log_transactions.create!(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND,
                                  abstract_session: abstract_session,
                                  data: { credit_was: credit_was,
                                          credit: user.participant.reload.system_credit_balance },
                                  amount: refund_amount,
                                  payment_transaction: self)
    true
  end

  def cancel!(certain_amount = nil)
    transaction_result = Braintree::Transaction.find(braintree_id)
    Rails.logger.info "started cancelling #{self}, certain_amount: #{certain_amount.inspect}"
    case transaction_result.status
    when Statuses::SUBMITTED_FOR_SETTLEMENT, Statuses::AUTHORIZED
      result = Braintree::Transaction.void(braintree_id)
      # <Braintree::SuccessfulResult transaction:#<Braintree::Transaction id: "bsgm92", type: "sale", amount: "17.99", status: "voided", created_at: 2014-02-18 00:40:34 UTC, credit_card_details: #<token: "bkcfrm", bin: "400934", last_4: "1881", card_type: "Visa", expiration_date: "11/2016", cardholder_name: nil, customer_location: "US", prepaid: "Unknown", healthcare: "Unknown", durbin_regulated: "Unknown", debit: "Unknown", commercial: "Unknown", payroll: "Unknown", country_of_issuance: "Unknown", issuing_bank: "Unknown">, customer_details: #<id: "2x59a3d6b36e5d498b83f7bb0e371bb001", first_name: nil, last_name: nil, email: "nfedyashev@gmail.com", company: nil, website: nil, phone: nil, fax: nil>, subscription_details: #<Braintree::Transaction::SubscriptionDetails:0x007fb6401519b0 @billing_period_end_date=nil, @billing_period_start_date=nil>, updated_at: 2014-02-18 03:30:36 UTC>>
      if result.success?
        self.status = result.transaction.status
        save!

        # because fake_braintree does not mock result.transaction.payment_instrument_type
        if Rails.env.test? || result.transaction.payment_instrument_type == BraintreeTransaction::PaymentInstrumentTypes::CREDIT_CARD
          data = {
            transaction_id: braintree_id,
            status: result.transaction.status,
            credit_card_number: ('*' * 12) + credit_card_last_4.to_s
          }
        elsif result.transaction.payment_instrument_type == BraintreeTransaction::PaymentInstrumentTypes::PAYPAL_ACCOUNT
          # status is not helpful here because it may return 'settled'(still)
          data = {
            # paypal_payment_id:       result.transaction.paypal_details.payment_id, # because it returned nil
            paypal_email: result.transaction.paypal_details.payer_email,
            paypal_token: result.transaction.paypal_details.token
          }
        else
          raise "unknown payment type: #{result.transaction.payment_instrument_type}"
        end

        user.log_transactions.create!(type: LogTransaction::Types::MONEY_REFUND,
                                      abstract_session: abstract_session,
                                      data: data,
                                      amount: amount,
                                      payment_transaction: self)

        if result.transaction.amount.to_f != amount.to_f
          Airbrake.notify(RuntimeError.new('requested refund amount and actual amount does not match'),
                          parameters: {
                            braintree_transaction_id: id,
                            requested_refund_amount: amount,
                            actual_refund_amount: result.transaction.amount,
                            debug_info: result.transaction.inspect
                          })
        end

        Rails.logger.info "successfully voided #{result.inspect}"
      else
        Rails.logger.info "failed in voiding attempt: #{result.message.inspect}"
        raise result.message.inspect
      end
    when Statuses::SETTLED, Statuses::SETTLING
      refund_amount = certain_amount.try(:round, 2) || amount.round(2)
      result = Braintree::Transaction.refund(braintree_id, refund_amount)
      if result.success?
        self.status = result.transaction.status
        save!

        case result.transaction.payment_instrument_type
        when BraintreeTransaction::PaymentInstrumentTypes::CREDIT_CARD
          data = {
            transaction_id: braintree_id,
            status: result.transaction.status,
            credit_card_number: ('*' * 12) + credit_card_last_4.to_s
          }
        when BraintreeTransaction::PaymentInstrumentTypes::PAYPAL_ACCOUNT
          # status is not helpful here because it may return 'settled'(still)
          data = {
            # paypal_payment_id:       result.transaction.paypal_details.payment_id, # because it returned nil
            paypal_email: result.transaction.paypal_details.payer_email,
            paypal_token: result.transaction.paypal_details.token
          }
        else
          raise "unknown payment type: #{result.transaction.payment_instrument_type}"
        end

        user.log_transactions.create!(type: LogTransaction::Types::MONEY_REFUND,
                                      abstract_session: abstract_session,
                                      data: data,
                                      amount: refund_amount,
                                      payment_transaction: self)

        if result.transaction.amount.to_f != refund_amount.to_f
          Airbrake.notify(RuntimeError.new('requested refund amount and actual amount does not match'),
                          parameters: {
                            braintree_transaction_id: id,
                            requested_refund_amount: refund_amount,
                            actual_refund_amount: result.transaction.amount,
                            debug_info: result.transaction.inspect
                          })
        end

        Rails.logger.info "successfully refunded #{result.inspect}"
      else
        Rails.logger.info "failed in refunding attempt: #{result.message.inspect}"
        raise result.message.inspect
      end
    else
      raise "can not deal with #{transaction_result.inspect} / #{transaction_result.status}"
    end
  end

  def money_refund!
    cancel!

    entry = Plutus::Entry.new(
      description: "Money refund - #{abstract_session.always_present_title}",
      commercial_document: self,
      debits: [
        { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: amount }
      ],
      credits: [
        { account_name: Accounts::Asset::MERCHANT, amount: amount }
      ]
    )
    entry.save!

    Mailer.money_refund_receipt(user.id, 'BraintreeTransaction', id).deliver_later
  end

  private

  def set_checked_at
    self.checked_at = Time.zone.now
  end
end
