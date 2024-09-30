# frozen_string_literal: true

# Customer Service Representative(admin on steroids)
class Csr
  def initialize(user)
    @user = user
  end

  # @return [IssuedSystemCredit]
  def issue_system_credit_refund(system_credit_refund_amount)
    raise ArgumentError, 'Must be positive' if system_credit_refund_amount <= 0

    credit = @user.receive_issued_system_credit!(amount: system_credit_refund_amount,
                                                 type: IssuedSystemCredit::Types::BOO_BOO_CREDIT,
                                                 status: IssuedSystemCredit::Statuses::OPEN)

    entry = Plutus::Entry.new(
      # NOTE: - description must contain "refund" word - otherwise it won't be displayed in admin interface
      description: 'System credit refund from CSR',
      commercial_document: credit,
      debits: [
        { account_name: Accounts::Expense::BOO_BOO, amount: system_credit_refund_amount }
      ],
      credits: [
        { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: system_credit_refund_amount }
      ]
    )
    entry.save!

    @user.log_transactions.create!(type: LogTransaction::Types::BOO_BOO_CSR_REFUND,
                                   data: {},
                                   amount: system_credit_refund_amount,
                                   payment_transaction: credit)

    @success_message = 'User has been refunded'

    credit
  end

  # @param [BraintreeTransaction]
  # @return [Boolean]
  def refund_braintree_transaction(braintree_transaction, refund_amount)
    refund_amount = refund_amount.to_f.round(2)

    raise ArgumentError, 'Must be positive' if refund_amount <= 0

    if refund_amount > braintree_transaction.amount.to_f
      raise ArgumentError,
            "Must be less than #{braintree_transaction.amount.to_f}"
    end

    transaction_result = Braintree::Transaction.find(braintree_transaction.braintree_id)
    if braintree_transaction.credit_card? && (transaction_result.status == BraintreeTransaction::Statuses::SUBMITTED_FOR_SETTLEMENT || transaction_result.status == BraintreeTransaction::Statuses::AUTHORIZED)
      result = Braintree::Transaction.void(braintree_transaction.braintree_id)
      # <Braintree::SuccessfulResult transaction:#<Braintree::Transaction id: "bsgm92", type: "sale", amount: "17.99", status: "voided", created_at: 2014-02-18 00:40:34 UTC, credit_card_details: #<token: "bkcfrm", bin: "400934", last_4: "1881", card_type: "Visa", expiration_date: "11/2016", cardholder_name: nil, customer_location: "US", prepaid: "Unknown", healthcare: "Unknown", durbin_regulated: "Unknown", debit: "Unknown", commercial: "Unknown", payroll: "Unknown", country_of_issuance: "Unknown", issuing_bank: "Unknown">, customer_details: #<id: "2x59a3d6b36e5d498b83f7bb0e371bb001", first_name: nil, last_name: nil, email: "nfedyashev@gmail.com", company: nil, website: nil, phone: nil, fax: nil>, subscription_details: #<Braintree::Transaction::SubscriptionDetails:0x007fb6401519b0 @billing_period_end_date=nil, @billing_period_start_date=nil>, updated_at: 2014-02-18 03:30:36 UTC>>
      if result.success?
        braintree_transaction.status = result.transaction.status
        braintree_transaction.save(validate: false)

        debit_account_type = case braintree_transaction.type
                             when TransactionTypes::IMMERSIVE
                               Accounts::Income::IMMERSIVE_SESSION_REVENUE
                             when TransactionTypes::LIVESTREAM
                               Accounts::Income::LIVESTREAM_SESSION_REVENUE
                             when TransactionTypes::RECORDED
                               Accounts::Income::RECORDED_SESSION_REVENUE
                             when TransactionTypes::RECORDING
                               Accounts::Income::RECORDING_REVENUE
                             else
                               raise "can not interpre #{braintree_transaction.type}"
                             end

        entry = Plutus::Entry.new(
          # NOTE: - description must contain "refund" word - otherwise it won't be displayed in admin interface
          description: 'Full money refund from CSR',
          commercial_document: braintree_transaction,
          debits: [
            { account_name: debit_account_type, amount: braintree_transaction.amount }
          ],
          credits: [
            { account_name: Accounts::Asset::MERCHANT, amount: braintree_transaction.amount }
          ]
        )
        entry.save!

        @user.log_transactions.create!(type: LogTransaction::Types::MONEY_CSR_REFUND,
                                       abstract_session: braintree_transaction.abstract_session,
                                       data: { original_transaction_amount: braintree_transaction.amount },
                                       amount: braintree_transaction.amount,
                                       payment_transaction: braintree_transaction)

        @success_message = 'User has been refunded'

        true
      else
        Rails.logger.info "failed in voiding attempt: #{result.message.inspect}"
        @error_message = result.message
        false
      end
    # TODO: #FIXME - also check status of paypal transaction(currently I know of just one status)
    elsif braintree_transaction.paypal? || (braintree_transaction.credit_card? && transaction_result.status == BraintreeTransaction::Statuses::SETTLED)
      result = Braintree::Transaction.refund(braintree_transaction.braintree_id, refund_amount)
      if result.success?
        braintree_transaction.status = result.transaction.status
        braintree_transaction.save(validate: false)

        description = (refund_amount == braintree_transaction.amount) ? 'Full money refund from CSR' : 'Partial money refund from CSR'

        # TODO: #FIXME - could be also credit replenishment via PayPal
        debit_account_type = case braintree_transaction.type
                             when TransactionTypes::IMMERSIVE
                               Accounts::Income::IMMERSIVE_SESSION_REVENUE
                             when TransactionTypes::LIVESTREAM
                               Accounts::Income::LIVESTREAM_SESSION_REVENUE
                             when TransactionTypes::RECORDED
                               Accounts::Income::RECORDED_SESSION_REVENUE
                             when TransactionTypes::RECORDING
                               Accounts::Income::RECORDING_REVENUE
                             else
                               raise "can not interpret #{braintree_transaction.type}"
                             end

        entry = Plutus::Entry.new(
          description: description,
          commercial_document: braintree_transaction,
          debits: [
            { account_name: debit_account_type, amount: refund_amount }
          ],
          credits: [
            { account_name: Accounts::Asset::MERCHANT, amount: refund_amount }
          ]
        )
        entry.save!

        @user.log_transactions.create!(type: LogTransaction::Types::MONEY_CSR_REFUND,
                                       data: { original_transaction_amount: braintree_transaction.amount },
                                       amount: refund_amount,
                                       abstract_session: braintree_transaction.abstract_session,
                                       payment_transaction: braintree_transaction)

        @success_message = 'User has been refunded'

        true
      else
        Rails.logger.info "failed in refunding attempt: #{result.message.inspect}"
        @error_message = result.message.inspect
        false
      end
    else
      raise "can not deal with #{transaction_result.inspect} / #{transaction_result.status}"
    end
  end

  attr_reader :success_message, :error_message
end
