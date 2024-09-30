# frozen_string_literal: true
class SystemCreditEntry < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # disable STI
  self.inheritance_column = :_type_disabled

  belongs_to :participant, touch: true
  belongs_to :commercial_document, polymorphic: true

  validates :amount, numericality: { greater_than: 0, allow_nil: false }
  validates :type, inclusion: { in: TransactionTypes::ALL }

  validates :commercial_document, presence: true, if: lambda { |bt|
                                                        bt.type == TransactionTypes::IMMERSIVE || bt.type == TransactionTypes::LIVESTREAM || bt.type == TransactionTypes::RECORDED
                                                      }

  scope :immersive_access, -> { where('type = ?', TransactionTypes::IMMERSIVE) }
  scope :livestream_access, -> { where('type = ?', TransactionTypes::LIVESTREAM) }
  scope :vod_access,       -> { where('type = ?', TransactionTypes::RECORDED) }

  scope :live_access,      -> { where(type: [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]) }

  scope :replenishment, -> { where('type = ?', TransactionTypes::REPLENISHMENT) }

  def system_credit_refund!(refund_amount)
    credit_was = user.system_credit_balance

    user.receive_issued_system_credit!(amount: refund_amount,
                                       type: IssuedSystemCredit::Types::CHOSEN_REFUND,
                                       status: IssuedSystemCredit::Statuses::OPEN)

    description = commercial_document ? "System Credit Refund - #{commercial_document.always_present_title}" : 'System Credit Refund'
    entry = Plutus::Entry.new(
      description: description,
      commercial_document: commercial_document,
      debits: [
        { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: refund_amount }
      ],
      credits: [
        { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: refund_amount }
      ]
    )
    entry.save!

    user.log_transactions.create!(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND,
                                  abstract_session: commercial_document, # TODO: - What if commercial_document is empty?
                                  data: { credit_was: credit_was,
                                          credit: user.participant.reload.system_credit_balance },
                                  amount: refund_amount,
                                  payment_transaction: self)
    true
  end

  private

  def user
    @user ||= participant.user
  end
end
