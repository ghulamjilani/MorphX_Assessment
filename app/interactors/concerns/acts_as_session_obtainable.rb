# frozen_string_literal: true

# require Rails.root.join('config/initializers/global_constants').to_s

module ActsAsSessionObtainable
  include ActionView::Helpers::NumberHelper
  include MoneyHelper

  def current_ability
    # @current_ability ||= ::AbilityLib::Legacy::AccountingAbility.new(@current_user)
    @current_ability ||= ::AbilityLib::ChannelAbility.new(@current_user).tap do |ability|
      ability.merge(::AbilityLib::AccessManagement::GroupAbility.new(@current_user))
      ability.merge(::AbilityLib::Blog::CommentAbility.new(@current_user))
      ability.merge(::AbilityLib::Blog::ImageAbility.new(@current_user))
      ability.merge(::AbilityLib::Blog::PostAbility.new(@current_user))
      ability.merge(::AbilityLib::StripeDb::ServiceSubscriptionAbility.new(@current_user))
      ability.merge(::AbilityLib::CommentAbility.new(@current_user))
      ability.merge(::AbilityLib::OrganizationAbility.new(@current_user))
      ability.merge(::AbilityLib::OrganizationMembershipAbility.new(@current_user))
      ability.merge(::AbilityLib::PendingRefundAbility.new(@current_user))
      ability.merge(::AbilityLib::RecordingAbility.new(@current_user))
      ability.merge(::AbilityLib::ReviewAbility.new(@current_user))
      ability.merge(::AbilityLib::SessionAbility.new(@current_user))
      ability.merge(::AbilityLib::SessionInvitedImmersiveParticipantshipAbility.new(@current_user))
      ability.merge(::AbilityLib::SessionInvitedLivestreamParticipantshipAbility.new(@current_user))
      ability.merge(::AbilityLib::SubscriptionAbility.new(@current_user))
      ability.merge(::AbilityLib::UserAbility.new(@current_user))
      ability.merge(::AbilityLib::VideoAbility.new(@current_user))
    end
  end

  def success_message
    @success_message ||= 'Success'
  end

  def error_message
    @error_message
  end

  def abstract_session
    @abstract_session ||= @session || @recording
  end

  def obtain_non_free_access_title
    paid_type_is_chosen! if @free_type_is_chosen.nil?
    if total_charge_amount.zero?
      Airbrake.notify(RuntimeError.new('charge_amount could not be zero'),
                      parameters: {
                        session: inspect
                      })
    end
    "Buy for #{as_currency total_charge_amount, @current_user}"
  end

  def pending_invitee?
    @pending_invitee ||= current_ability.can?(:accept_or_reject_invitation, abstract_session)
  end

  def free_type_is_chosen!
    @free_type_is_chosen = true
  end

  def paid_type_is_chosen!
    @free_type_is_chosen = false
  end

  def discount_amount
    return 0 unless @discount

    if @discount.amount_off_cents
      (@discount.amount_off_cents.to_f / 100).round(2)
    else
      (charge_amount / 100 * @discount.percent_off_precise).round(2)
    end
  end

  def total_charge_amount
    charge_amount - discount_amount
  end

  # FIXME: BRAINTREE
  # @param transaction_type - TransactionTypes::IMMERSIVE or TransactionTypes::LIVESTREAM
  # @return [BraintreeTransaction] or FalseClass
  def create_braintree_transaction(payment_method_nonce, transaction_type)
    result = if @current_user.braintree_customer_id.present?
               Braintree::Transaction.sale(
                 amount: total_charge_amount,
                 customer: {
                   first_name: @current_user.first_name,
                   last_name: @current_user.last_name,
                   email: @current_user.email
                 },
                 payment_method_nonce: payment_method_nonce
               )
             else
               Braintree::Transaction.sale(
                 amount: total_charge_amount,
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
      false
    else
      if @current_user.braintree_customer_id.blank?
        # save customer so that he doesn't need to enter CC again on next purchase
        @current_user.update(braintree_customer_id: result.transaction.customer_details.id)
      end

      case result.transaction.payment_instrument_type
      when BraintreeTransaction::PaymentInstrumentTypes::CREDIT_CARD
        braintree_transaction = BraintreeTransaction.create!(abstract_session: abstract_session,
                                                             amount: result.transaction.amount,
                                                             braintree_id: result.transaction.id,
                                                             processor_authorization_code: result.transaction.processor_authorization_code,
                                                             tax_exempt: result.transaction.tax_exempt,
                                                             tax_amount: result.transaction.tax_amount,

                                                             card_type: result.transaction.credit_card_details.card_type,
                                                             credit_card_last_4: result.transaction.credit_card_details.last_4,

                                                             status: result.transaction.status,
                                                             type: transaction_type,
                                                             user_id: @current_user.id)
      when BraintreeTransaction::PaymentInstrumentTypes::PAYPAL_ACCOUNT
        braintree_transaction = BraintreeTransaction.create!(abstract_session: abstract_session,
                                                             amount: result.transaction.amount,
                                                             braintree_id: result.transaction.id,
                                                             processor_authorization_code: result.transaction.processor_authorization_code,
                                                             tax_exempt: result.transaction.tax_exempt,
                                                             tax_amount: result.transaction.tax_amount,

                                                             paypal_payment_id: result.transaction.paypal_details.payment_id,
                                                             paypal_payer_email: result.transaction.paypal_details.payer_email,
                                                             paypal_token: result.transaction.paypal_details.token,
                                                             paypal_debug_id: result.transaction.paypal_details.debug_id,
                                                             paypal_authorization_id: result.transaction.paypal_details.authorization_id,

                                                             status: result.transaction.status,
                                                             type: transaction_type,
                                                             user_id: @current_user.id)
      else
        raise "unknown payment type: #{result.transaction.payment_instrument_type}"
      end

      submit_result = Braintree::Transaction.submit_for_settlement(braintree_transaction.braintree_id)
      # <Braintree::SuccessfulResult transaction:#<Braintree::Transaction id: "6d8m4g", type: "sale", amount: "5.0", status: "submitted_for_settlement", created_at: 2014-02-16 05:22:45 UTC, credit_card_details: #<token: "4nndg2", bin: "601111", last_4: "1117", card_type: "Discover", expiration_date: "11/2017", cardholder_name: nil, customer_location: "US", prepaid: "Unknown", healthcare: "Unknown", durbin_regulated: "Unknown", debit: "Unknown", commercial: "Unknown", payroll: "Unknown", country_of_issuance: "Unknown", issuing_bank: "Unknown">, customer_details: #<id: "21508346", first_name: nil, last_name: nil, email: nil, company: nil, website: nil, phone: nil, fax: nil>, subscription_details: #<Braintree::Transaction::SubscriptionDetails:0x007fb4dbf6ff08 @billing_period_end_date=nil, @billing_period_start_date=nil>, updated_at: 2014-02-16 05:42:58 UTC>>

      if !submit_result.success?
        Airbrake.notify(RuntimeError.new(submit_result.inspect),
                        parameters: {
                          session_id: abstract_session.id,
                          current_user_id: @current_user.id
                        })

        @error_message = submit_result.message
        false
      else
        braintree_transaction.submit_for_settlement!

        braintree_transaction
      end
    end
  end

  # @param transaction_type - TransactionTypes::IMMERSIVE or TransactionTypes::LIVESTREAM
  # @return [StripeTransaction] or FalseClass
  def create_stripe_transaction(transaction_type, token = nil, params = {})
    @charge_amount = (total_charge_amount * 100).to_i
    begin
      if @current_user.has_payment_info?
        # check if this is not existing card token
        @customer = @current_user.stripe_customer
        @source = if token&.start_with?('tok_')
                    Stripe::Customer.create_source(@customer.id, { source: token })
                  elsif token&.start_with?('card_')
                    @current_user.find_stripe_customer_source(token)
                  end

        if @source
          @customer.default_source = @source
          @customer.save
        end
      else
        @customer = Stripe::Customer.create(
          email: @current_user.email,
          description: @current_user.public_display_name,
          source: token
        )
        @current_user.stripe_customer_id = @customer.id
        @current_user.save(validate: false)
        token = nil
      end
    rescue StandardError => e
      @error_message = e.message
      return false
    end

    @country = params[:country] || @source&.address_country
    @zip_code = params[:zip_code] || @source&.address_zip
    # TODO: уточнить по налогам актуального штата
    @tax = 0

    begin
      invoice_params = {
        customer: @customer.id,
        # default_tax_rates: [@tax], # Skip For now because we don't have tax
        description: "Obtain #{transaction_type} for #{abstract_session.class.name}##{abstract_session.id}.#{@discount ? " Coupon: #{@discount.name}" : ''}"
      }
      invoice_params[:default_source] = @source if @source
      invoice = Stripe::Invoice.create(invoice_params)
      invoice_item_params = {
        customer: @customer.id,
        amount: @charge_amount,
        currency: 'usd',
        description: "Obtain #{transaction_type} for #{abstract_session.class.name}##{abstract_session.id}.#{@discount ? " Coupon: #{@discount.name}" : ''}",
        invoice: invoice.id
      }
      Stripe::InvoiceItem.create(invoice_item_params)

      invoice.pay
      invoice = Stripe::Invoice.retrieve(invoice.id)
      charge = Stripe::Charge.retrieve(invoice.charge)
    rescue StandardError => e
      @error_message = e.message
      return false
    end
    if invoice.paid
      @stripe_transaction = PaymentTransaction.find_or_initialize_by(provider: :stripe, pid: charge.id)
      @stripe_transaction.amount = invoice.amount_paid
      @stripe_transaction.amount_currency = invoice.currency
      @stripe_transaction.type = transaction_type
      @stripe_transaction.user = @current_user
      @stripe_transaction.purchased_item = abstract_session
      @stripe_transaction.credit_card_last_4 = charge.source.last4
      @stripe_transaction.card_type = charge.source.brand
      @stripe_transaction.status = charge.status
      @stripe_transaction.country = charge.source.country
      @stripe_transaction.zip = charge.source.address_zip
      @stripe_transaction.name_on_card = charge.source.name
      @stripe_transaction.tax_cents = (invoice.amount_paid / 100.0 * @tax).round
      @stripe_transaction.checked_at = Time.zone.at(charge.created)
      @stripe_transaction.save

      @stripe_transaction
    else
      @error_message = invoice.status
      false
    end
  end

  # @param transaction_type - TransactionTypes::IMMERSIVE or TransactionTypes::LIVESTREAM
  # @return [StripeTransaction] or FalseClass
  # {"payer_email" => "stdashulya-buyer@icloud.com",
  #  "payer_id" => "U36HAQQYFNDSC",
  #  "payer_status" => "VERIFIED",
  #  "first_name" => "test",
  #  "last_name" => "buyer",
  #  "address_name" => "test buyer",
  #  "address_street" => "1 Main St",
  #  "address_city" => "San Jose",
  #  "address_state" => "CA",
  #  "address_country_code" => "US",
  #  "address_zip" => "95131",
  #  "residence_country" => "US",
  #  "txn_id" => "66A28370FR770264A",
  #  "mc_currency" => "USD",
  #  "mc_fee" => "0.39",
  #  "mc_gross" => "2.99",
  #  "protection_eligibility" => "ELIGIBLE",
  #  "payment_fee" => "0.39",
  #  "payment_gross" => "2.99",
  #  "payment_status" => "Completed",
  #  "payment_type" => "instant",
  #  "handling_amount" => "0.00",
  #  "shipping" => "0.00",
  #  "tax" => "0",
  #  "item_name" => "Gürhard Bradley Live Session",
  #  "item_number" => "131",
  #  "quantity" => "1",
  #  "txn_type" => "web_accept",
  #  "payment_date" => "2020-10-27T17:37:26Z",
  #  "business" => "stdashulya-facilitator@icloud.com",
  #  "receiver_id" => "E4ZELG6C6Z8SA",
  #  "notify_version" => "UNVERSIONED",
  #  "verify_sign" => "A9uLMCoatQ4AuxhPJxWzn2efUhziA-gKa0wlxnWnDaWXaqsu68e9o2Xp",
  #  "country" => "US",
  #  "discount" => "",
  #  "provider" => "paypal",
  #  "type" => "paid_livestream",
  #  "user_id" => "45",
  #  "zip" => "66666",
  #  "controller" => "sessions",
  #  "action" => "confirm_paypal_purchase",
  #  "channel_id" => "1",
  #  "id" => "131"}

  def create_paypal_transaction(transaction_type, params)
    # sale = PayPal::SDK::REST::DataTypes::Sale.find(params[:txn_id] || params[:tx])
    payment = PayPal::SDK::REST::Payment.find(params[:paymentID])
    if payment.execute(payer_id: params[:payerID])
      pp_transaction = payment.transactions[0]
      sale = pp_transaction.related_resources[0].sale
      amount_cents = ((pp_transaction.amount.total.to_f - pp_transaction.amount.details.tax.to_f) * 100).to_i
      @transaction = PaymentTransaction.new(provider: :paypal)
      @transaction.amount = amount_cents
      @transaction.tax_cents = (pp_transaction.amount.details.tax.to_f * 100).to_i
      @transaction.country = payment.payer.payer_info.country_code
      @transaction.zip = payment.payer.payer_info.shipping_address.postal_code
      @transaction.type = transaction_type
      @transaction.user = @current_user
      @transaction.purchased_item = abstract_session
      @transaction.pid = sale.id
      @transaction.status = sale.state.to_s
      @transaction.payer_email = @current_user.email
      @transaction.checked_at = sale.create_time
      @transaction.save!

      @transaction
    else
      raise payment.error
    end
  end

  # @return [SystemCreditEntry] created SystemCreditEntry object
  def create_system_credit_transaction(transaction_type)
    result = @current_user.participant.system_credit_entries.create!(
      type: transaction_type,
      commercial_document: abstract_session,
      amount: charge_amount,
      description: "Purchase with system credit - #{abstract_session.always_present_title}"
    )

    @current_user.participant.touch if result

    result
  end
end
