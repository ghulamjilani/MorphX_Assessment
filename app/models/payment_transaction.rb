# frozen_string_literal: true
class PaymentTransaction < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # disable STI
  self.inheritance_column = :_type_disabled

  belongs_to :purchased_item, polymorphic: true, touch: true
  belongs_to :user
  has_one :pending_refund
  has_one :affiliate_everflow_tracked_payment, class_name: 'Affiliate::Everflow::TrackedPayment', dependent: :destroy
  has_many :log_transactions, as: :payment_transaction
  has_many :refunds
  belongs_to :payout

  scope :immersive_access, -> { where(type: TransactionTypes::IMMERSIVE) }
  scope :livestream_access, -> { where(type: TransactionTypes::LIVESTREAM) }
  scope :vod_access, -> { where(type: TransactionTypes::RECORDED) }
  scope :recording_access, -> { where(type: TransactionTypes::RECORDING) }
  scope :document_access, -> { where(type: TransactionTypes::DOCUMENT) }
  scope :live_access, -> { where(type: [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]) }
  scope :replenishment, -> { where(type: TransactionTypes::REPLENISHMENT) }
  scope :channel_subscription, -> { where(type: TransactionTypes::CHANNEL_SUBSCRIPTION) }
  # TODO: RENAME
  scope :service_subscription, -> { where(type: TransactionTypes::SERVICE_SUBSCRIPTION) }

  scope :success, -> { where(status: Statuses::SUCCESS) }
  scope :refund, -> { where(status: Statuses::REFUND) }
  scope :not_failed, lambda {
    where(status: [Statuses::APPROVED, Statuses::SUCCEEDED, Statuses::COMPLETED, Statuses::PENDING])
  }
  scope :success_and_refund, lambda {
    where(status: [Statuses::APPROVED, Statuses::SUCCEEDED, Statuses::COMPLETED, Statuses::REFUND])
  }
  scope :not_archived, -> { where(archived: false) }

  TYPES = %w[StripeDb::Subscription StripeDb::ServiceSubscription Session Recording Booking::Booking].freeze

  module Statuses
    # Credit cards
    APPROVED = 'approved'
    SUCCEEDED = 'succeeded'
    COMPLETED = 'completed'
    PAID = 'paid'
    PENDING = 'pending'
    FAILED = 'failed'
    REFUND = 'refund'

    ALL = [
      APPROVED,
      SUCCEEDED,
      COMPLETED,
      PENDING,
      FAILED,
      REFUND,
      PAID
    ].freeze
    SUCCESS = [
      APPROVED,
      SUCCEEDED,
      COMPLETED,
      PAID
    ].freeze
  end

  module PaymentInstrumentTypes
    CREDIT_CARD = 'credit_card'
  end

  enum payout_status: {
    pending: 0, # default state
    paid: 1, # payout created and money transfer created
    declined: 2 # you can set it from service_admin_panel, this should exclude transaction from upcoming payout
  }

  # validates :status, inclusion: {in: Statuses::ALL}
  validates :type, inclusion: { in: ::TransactionTypes::ALL }
  validates :purchased_item, presence: true, if: lambda { |bt|
    bt.type == TransactionTypes::IMMERSIVE || bt.type == TransactionTypes::LIVESTREAM || bt.type == TransactionTypes::RECORDED
  }
  # because state_machine is abandoned and with Rails 4.2 :initial option is simply ignored
  after_initialize :set_initial_status
  before_validation :set_checked_at, if: :status_changed?
  after_destroy do
    PendingRefund.where(payment_transaction: self).map(&:destroy)
  end
  after_create :create_contact
  after_commit :create_reports
  %w[paypal stripe].each do |provider|
    define_method("#{provider}?") do
      self.provider == provider
    end
  end
  Statuses::ALL.each do |status|
    define_method("#{status}?") do
      self.status == status
    end
  end

  def total_amount
    amount + tax_cents.to_i
  end

  def tax_amount
    (tax_cents.to_i / 100.0).round(2)
  end

  def set_initial_status
    self.status ||= :unauthorized if has_attribute?(:status)
  end

  def credit_card?
    credit_card_last_4.present?
  end

  def receipt_title
    credit_card? ? 'Stripe ID' : 'PayPal Email'
  end

  def receipt_value
    credit_card? ? pid : payer_email
  end

  def system_credit_refund!(refund_amount)
    credit_was = user.system_credit_balance

    user.receive_issued_system_credit!(amount: refund_amount,
                                       type: IssuedSystemCredit::Types::CHOSEN_REFUND,
                                       status: IssuedSystemCredit::Statuses::OPEN)

    entry = Plutus::Entry.new(
      description: "System credit refund - #{purchased_item.always_present_title}",
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
                                  abstract_session: purchased_item,
                                  data: { credit_was: credit_was,
                                          credit: user.participant.reload.system_credit_balance },
                                  amount: refund_amount,
                                  payment_transaction: self)
    true
  end

  def cancel_stripe!(certain_amount = nil, reason = nil)
    raise 'not allowed' unless payout_status == 'pending'

    transaction_result = Stripe::Charge.retrieve(pid)
    Rails.logger.info "started cancelling #{self}, certain_amount: #{certain_amount.inspect}"
    if transaction_result.status == Statuses::SUCCEEDED || transaction_result.status == Statuses::PENDING
      refund_amount = (certain_amount || total_amount).to_i
      data = {
        amount: refund_amount,
        charge: pid,
        reason: reason
      }
      begin
        result = Stripe::Refund.create(data)
      rescue StandardError => e
        result = Hashie::Mash.new
        Rails.logger.info "can't refund #{e.inspect}"
        raise e.message.inspect
      end

      if result.status
        begin
          Refund.create!(payment_transaction_id: id, pid: result.id, provider: :stripe)
        rescue StandardError
          return
        end

        charge = Stripe::Charge.retrieve(pid)
        self.status = charge.refunded ? Statuses::REFUND : charge.status
        save!

        data = {
          transaction_id: pid,
          status: result.status,
          refund_id: result.id,
          credit_card_number: ('*' * 12) + credit_card_last_4.to_s,
          refund: true
        }

        buyer_lt = user.log_transactions.find_or_create_by(type: LogTransaction::Types::MONEY_REFUND,
                                                           abstract_session: purchased_item,
                                                           data: data,
                                                           amount: refund_amount / 100.0,
                                                           payment_transaction: self)

        case purchased_item
        when Session
          if purchased_item.finished?
            creator = purchased_item.presenter.user
            creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::NET_INCOME,
                                                        abstract_session: purchased_item,
                                                        data: data,
                                                        amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                        payment_transaction: self)
          end
        when Recording
          creator = purchased_item.channel.organizer
          creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::NET_INCOME,
                                                      abstract_session: purchased_item,
                                                      data: data,
                                                      amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                      payment_transaction: self)
        when StripeDb::Subscription
          # total_amount includes tax, so for refunding(-) from creator we need to exclude it
          # because incoming(+) transaction doesn't include it
          creator_refund_amount = ((refund_amount == total_amount) ? amount : refund_amount).to_i
          creator = purchased_item.channel.organizer
          creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION,
                                                      abstract_session: purchased_item.stripe_plan,
                                                      data: data,
                                                      amount: (-creator_refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                      payment_transaction: self)
        end

        entry = Plutus::Entry.new(
          description: "Money refund - #{purchased_item.always_present_title}",
          commercial_document: self,
          debits: [
            { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: (refund_amount / 100.0).round(2) }
          ],
          credits: [
            { account_name: Accounts::Asset::MERCHANT, amount: (refund_amount / 100.0).round(2) }
          ]
        )
        entry.save!

        Mailer.money_refund_receipt(user.id, buyer_lt.id).deliver_later

        if result.amount != refund_amount
          Airbrake.notify(RuntimeError.new('requested refund amount and actual amount does not match'),
                          parameters: {
                            payment_transaction_id: id,
                            requested_refund_amount: certain_amount,
                            actual_refund_amount: result.amount / 100.0,
                            debug_info: result.inspect
                          })
        end

        Rails.logger.info "successfully refunded #{result.inspect}"
      else
        Rails.logger.info "failed in refunding attempt: #{result.inspect}"
        raise result.message.inspect
      end
    else
      raise "can not deal with #{transaction_result.inspect} / #{transaction_result.status}"
    end
  end

  def cancel_paypal!(certain_amount = nil, reason = nil)
    raise 'not allowed' unless payout_status == 'pending'

    sale = PayPal::SDK::REST::DataTypes::Sale.find(pid)
    refund_amount = ((certain_amount || total_amount) / 100.0).round(2).to_s
    refund_params = if certain_amount
                      { amount: {
                        total: refund_amount,
                        currency: amount_currency.upcase,
                        reason: reason
                      } }
                    else
                      {}
                    end
    refund = sale.refund(refund_params)
    if refund.success?
      Rails.logger.info "Refund[#{refund.id}] Success"

      begin
        Refund.create!(payment_transaction_id: id, pid: refund.id, provider: :paypal)
      rescue StandardError
        return
      end

      if certain_amount == total_amount
        self.status = Statuses::REFUND
      end
      save!

      data = {
        transaction_id: pid,
        status: refund.state,
        refund: true
      }

      buyer_lt = user.log_transactions.create!(type: LogTransaction::Types::MONEY_REFUND,
                                               abstract_session: purchased_item,
                                               data: data,
                                               amount: refund_amount,
                                               payment_transaction: self)

      Mailer.money_refund_receipt(user.id, buyer_lt.id).deliver_later

      case purchased_item
      when Session
        if purchased_item.finished?
          creator = purchased_item.presenter.user
          creator.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                           abstract_session: purchased_item,
                                           data: data,
                                           amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                           payment_transaction: self)
        end
      when Recording
        creator = purchased_item.channel.organizer
        creator.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                         abstract_session: purchased_item,
                                         data: data,
                                         amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                         payment_transaction: self)
      when StripeDb::Subscription
        creator = purchased_item.channel.organizer
        creator.log_transactions.create!(type: LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION,
                                         abstract_session: purchased_item.stripe_plan,
                                         data: data,
                                         amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                         payment_transaction: self)
      end

      entry = Plutus::Entry.new(
        description: "Money refund - #{purchased_item.always_present_title}",
        commercial_document: self,
        debits: [
          { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: (refund_amount.to_f / 100.0).round(2) }
        ],
        credits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (refund_amount.to_f / 100.0).round(2) }
        ]
      )
      entry.save!

      if refund.amount != refund_amount
        Airbrake.notify(RuntimeError.new('requested refund amount and actual amount does not match'),
                        parameters: {
                          stripe_transaction_id: id,
                          requested_refund_amount: certain_amount,
                          actual_refund_amount: refund.amount,
                          debug_info: refund.inspect
                        })
      end
    else
      Rails.logger.error refund.error.inspect
    end
  end

  def money_refund!(certain_amount = nil, reason = nil)
    raise 'not allowed' unless payout_status == 'pending'

    refund_amount = certain_amount || total_amount
    if stripe?
      cancel_stripe!(refund_amount, reason)
    elsif paypal?
      cancel_paypal!(refund_amount, reason)
    end
  end

  def image_url
    if credit_card?
      "cards/#{card_type.downcase}.svg"
    elsif provider == 'paypal'
      'https://assets.braintreegateway.com/payment_method_logo/paypal.png?environment=sandbox'
    else
      ''
      # raise ArgumentError, "can not interpret #{self.inspect}"
    end
  end

  def refunds
    if stripe?
      @refunds ||= Stripe::Refund.list(charge: pid, limit: 100)
    elsif paypal?
      sale = PayPal::SDK::REST::DataTypes::Sale.find(pid)
      payment = PayPal::SDK::REST::DataTypes::Payment.find(sale.parent_payment)
      @refunds ||= payment.transactions[0].related_resources.select do |rr|
        rr.refund.id.present?
      rescue StandardError
        nil
      end.map(&:refund)
    else
      @refunds = []
    end
  rescue StandardError
    @refunds = []
  end

  def track_affiliate_transaction
    # for now track only subscriptions
    return unless %w[StripeDb::ServiceSubscription StripeDb::Subscription].include?(purchased_item_type)
    return if purchased_item.affiliate_everflow_transaction_id.blank?

    ::Affiliate::Everflow::TrackPaymentTransactionJob.perform_async(id, purchased_item.affiliate_everflow_transaction_id)
  end

  private

  def set_checked_at
    self.checked_at = Time.zone.now
  end

  def create_contact
    for_user = case purchased_item
               when Session, Video, Recording
                 purchased_item&.organizer
               when StripeDb::Subscription
                 purchased_item&.user
               end
    return unless for_user

    contact = Contact.find_or_initialize_by(for_user: for_user, contact_user: user)
    contact.name = user.public_display_name
    contact.email = user.email
    contact.save
    if contact.status != 'subscription' && contact.status != 'trial'
      contact.status = :one_time
      contact.save
    end
    user.follow(for_user)
  end

  def create_reports
    if Statuses::SUCCESS.include?(self.status) && purchased_item_type != 'StripeDb::ServiceSubscription'
      ReportJobs::V1::RevenueOrganization.perform_async(id, 'PaymentTransaction')
      ReportJobs::V1::ReportPurchasedItem.perform_async(id, 'PaymentTransaction')
    end
  end
end
