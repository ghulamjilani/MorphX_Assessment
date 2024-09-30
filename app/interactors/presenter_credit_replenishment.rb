# frozen_string_literal: true

class PresenterCreditReplenishment
  extend ActiveSupport::Concern

  def initialize(current_user, charge_amount = nil)
    @current_user  = current_user
    @charge_amount = charge_amount
  end

  def execute(payment_method_nonce)
    result = if @current_user.braintree_customer_id.present?
               Braintree::Transaction.sale(
                 amount: @charge_amount,
                 customer: {
                   first_name: @current_user.first_name,
                   last_name: @current_user.last_name,
                   email: @current_user.email
                 },
                 payment_method_nonce: payment_method_nonce
               )
             else
               Braintree::Transaction.sale(
                 amount: @charge_amount,
                 payment_method_nonce: payment_method_nonce,
                 customer: {
                   first_name: @current_user.first_name,
                   last_name: @current_user.last_name,
                   email: @current_user.email
                 },
                 options: {
                   store_in_vault: true
                 }
               )
             end

    if !result.success?
      @error_message = result.message
      return false
    else
      if @current_user.braintree_customer_id.blank?
        # save customer so that he doesn't need to enter CC again on next purchase
        @current_user.update(braintree_customer_id: result.transaction.customer_details.id)
      end

      case result.transaction.payment_instrument_type
      when BraintreeTransaction::PaymentInstrumentTypes::CREDIT_CARD
        image_url = "https://assets.braintreegateway.com/payment_method_logo/#{result.transaction.credit_card_details.card_type.downcase}.png?environment=#{Braintree::Configuration.environment}"

        braintree_transaction = BraintreeTransaction.create!(amount: result.transaction.amount,
                                                             braintree_id: result.transaction.id,

                                                             credit_card_last_4: result.transaction.credit_card_details.last_4,

                                                             status: result.transaction.status,
                                                             type: 'replenishment',
                                                             user_id: @current_user.id)

      when BraintreeTransaction::PaymentInstrumentTypes::PAYPAL_ACCOUNT
        image_url = "https://assets.braintreegateway.com/payment_method_logo/paypal.png?environment=#{Braintree::Configuration.environment}"

        braintree_transaction = BraintreeTransaction.create!(amount: result.transaction.amount,
                                                             braintree_id: result.transaction.id,

                                                             paypal_payment_id: result.transaction.paypal_details.payment_id,
                                                             paypal_payer_email: result.transaction.paypal_details.payer_email,
                                                             paypal_token: result.transaction.paypal_details.token,
                                                             paypal_debug_id: result.transaction.paypal_details.debug_id,
                                                             paypal_authorization_id: result.transaction.paypal_details.authorization_id,

                                                             status: result.transaction.status,
                                                             type: 'replenishment',
                                                             user_id: @current_user.id)
      else
        raise "unknown payment type: #{result.transaction.payment_instrument_type}"
      end

      submit_result = Braintree::Transaction.submit_for_settlement(braintree_transaction.braintree_id)
      # <Braintree::SuccessfulResult transaction:#<Braintree::Transaction id: "6d8m4g", type: "sale", amount: "5.0", status: "submitted_for_settlement", created_at: 2014-02-16 05:22:45 UTC, credit_card_details: #<token: "4nndg2", bin: "601111", last_4: "1117", card_type: "Discover", expiration_date: "11/2017", cardholder_name: nil, customer_location: "US", prepaid: "Unknown", healthcare: "Unknown", durbin_regulated: "Unknown", debit: "Unknown", commercial: "Unknown", payroll: "Unknown", country_of_issuance: "Unknown", issuing_bank: "Unknown">, customer_details: #<id: "21508346", first_name: nil, last_name: nil, email: nil, company: nil, website: nil, phone: nil, fax: nil>, subscription_details: #<Braintree::Transaction::SubscriptionDetails:0x007fb4dbf6ff08 @billing_period_end_date=nil, @billing_period_start_date=nil>, updated_at: 2014-02-16 05:42:58 UTC>>

      if !submit_result.success?
        Airbrake.notify(RuntimeError.new(submit_result.inspect),
                        parameters: { current_user_id: @current_user.id })
        @error_messsage = submit_result.message
      else
        if @current_user.braintree_customer_id.blank?
          # save customer so that he doesn't need to enter CC again on next purchase
          @current_user.update(braintree_customer_id: result.transaction.customer_details.id)
        end

        braintree_transaction.submit_for_settlement!

        entry = Plutus::Entry.new(
          description: 'System credit replenishment',
          commercial_document: braintree_transaction,
          debits: [
            { account_name: Accounts::Asset::MERCHANT, amount: @charge_amount }
          ],
          credits: [
            { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: @charge_amount }
          ]
        )
        entry.save!

        case result.transaction.payment_instrument_type
        when BraintreeTransaction::PaymentInstrumentTypes::CREDIT_CARD
          data = { credit_card_number: ('*' * 12) + result.transaction.credit_card_details.last_4.to_s }
        when BraintreeTransaction::PaymentInstrumentTypes::PAYPAL_ACCOUNT
          data = {
            paypal_payment_id: result.transaction.paypal_details.payment_id,
            paypal_payer_email: result.transaction.paypal_details.payer_email,
            paypal_token: result.transaction.paypal_details.token
          }
        else
          raise "unknown payment type: #{result.transaction.payment_instrument_type}"
        end

        @current_user.log_transactions.create!(type: LogTransaction::Types::CREDIT_REPLENISHMENT,
                                               image_url: image_url,
                                               data: data,
                                               amount: result.transaction.amount,
                                               payment_transaction: result.transaction)

        @current_user
          .presenter
          .issued_presenter_credits
          .create!(amount: result.transaction.amount, type: IssuedPresenterCredit::Types::REPLENISHMENT)

        @success_message = I18n.t('views.profiles.replenishment_success_message')
      end
    end
    true
  end

  attr_reader :success_message, :error_message
end
