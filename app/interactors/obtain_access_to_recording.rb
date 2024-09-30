# frozen_string_literal: true

class ObtainAccessToRecording
  extend ActiveSupport::Concern

  include ActsAsSessionObtainable

  def initialize(recording, current_user)
    @recording = recording
    @current_user = current_user

    # otherwise "obtain access to free recording" CTA scenario for a new user would fail
    if @current_user.present? && @current_user.participant.blank?
      @current_user.create_participant!
    end

    @participant = current_user.try(:participant)
  end

  # This method is used only in view templates
  def could_be_obtained?
    can_purchase? || can_take_for_free?
  end

  def execute(params = {})
    if params[:stripe_token] || params[:stripe_card]
      execute_stripe(params[:stripe_token] || params[:stripe_card], params)
    elsif params[:provider] == 'paypal'
      execute_paypal(params)
    else
      execute_system_credit
    end
  end

  def execute_system_credit
    if charge_amount.zero?
      raise 'not allowed' unless can_take_for_free?
    else
      raise 'not allowed' unless current_ability.can?(:purchase_with_system_credit, @recording)

      system_credit_entry = create_system_credit_transaction(TransactionTypes::RECORDING)

      entry = Plutus::Entry.new(
        description: "Sold Recording Video - #{@recording.always_present_title}",
        commercial_document: system_credit_entry,
        debits: [
          { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: @recording.purchase_price },
          { account_name: Accounts::COGS::RECORDING_VENDOR_EARNINGS, amount: earnings_from_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDING_REVENUE,
            amount: (@recording.purchase_price - @recording.service_fee) },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @recording.service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_member }
        ]
      )
      entry.save!
    end

    return false if @error_message.present?

    obtain_access

    return false if @error_message.present?

    assign_revenue_to_organizer(system_credit_entry) unless charge_amount.zero?

    notify_user(nil)
  end

  def execute_stripe(token, params = {})
    if charge_amount.zero?
      raise 'not allowed' unless can_take_for_free?

      stripe_transaction = nil
    else
      raise 'not allowed' unless current_ability.can?(:purchase, @recording)

      stripe_transaction = create_stripe_transaction(TransactionTypes::RECORDING, token, params)

      return false if stripe_transaction == false

      charge = Stripe::Charge.retrieve(stripe_transaction.pid)
      transaction = begin
        Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
      rescue StandardError
        nil
      end
      fee = begin
        (transaction.fee / 100.0).round(2)
      rescue StandardError
        0
      end
      tax = (stripe_transaction.tax_cents / 100.0).round(2)

      entry = Plutus::Entry.new(
        description: "Sold Recording Video - #{@recording.always_present_title}",
        commercial_document: stripe_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (stripe_transaction.amount / 100.0).round(2) + tax },
          { account_name: Accounts::COGS::RECORDING_VENDOR_EARNINGS, amount: earnings_from_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDING_REVENUE,
            amount: (stripe_transaction.amount / 100.0) - @recording.service_fee - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @recording.service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_member }
        ]
      )
      entry.save!

      if stripe_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + stripe_transaction.credit_card_last_4.to_s }
      else
        raise "unknown payment type: #{stripe_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_RECORDING,
                                             abstract_session: @recording,
                                             image_url: stripe_transaction.image_url,
                                             data: data,
                                             amount: -stripe_transaction.total_amount / 100.0,
                                             payment_transaction: stripe_transaction)
    end

    return false if @error_message.present?

    obtain_access

    return false if @error_message.present?

    assign_revenue_to_organizer(stripe_transaction) unless charge_amount.zero?

    notify_user(stripe_transaction.try(:id))
  end

  def execute_paypal(params = {})
    if charge_amount.zero?
      raise 'not allowed' unless can_take_for_free?

      paypal_transaction = nil
    else
      raise 'not allowed' unless current_ability.can?(:purchase, @recording)

      paypal_transaction = create_paypal_transaction(TransactionTypes::RECORDING, params)

      return false if paypal_transaction == false

      begin
        sale = PayPal::SDK::REST::DataTypes::Sale.find(paypal_transaction.pid)
        fee = sale.transaction_fee.value.to_f
      rescue StandardError
        fee = 0
      end
      tax = (paypal_transaction.tax_cents / 100.0).round(2)

      entry = Plutus::Entry.new(
        description: "Sold Recording Video - #{@recording.always_present_title}",
        commercial_document: paypal_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (paypal_transaction.amount / 100.0).round(2) + tax },
          { account_name: Accounts::COGS::RECORDING_VENDOR_EARNINGS, amount: earnings_from_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDING_REVENUE,
            amount: (paypal_transaction.amount / 100.0) - @recording.service_fee - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @recording.service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_member }
        ]
      )
      entry.save!

      if paypal_transaction
        data = { paypal_payment_id: paypal_transaction.pid, paypal_payer_email: paypal_transaction.payer_email }
      else
        raise "unknown payment type: #{paypal_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_RECORDING,
                                             abstract_session: @recording,
                                             image_url: paypal_transaction.image_url,
                                             data: data,
                                             amount: -paypal_transaction.total_amount / 100.0,
                                             payment_transaction: paypal_transaction)
    end

    return false if @error_message.present?

    obtain_access

    return false if @error_message.present?

    assign_revenue_to_organizer(paypal_transaction) unless charge_amount.zero?

    notify_user(paypal_transaction.try(:id))
  end

  def obtain_non_free_access_title
    "Watch #{as_currency charge_amount, @current_user}"
  end

  def can_take_for_free?
    @can_take_for_free ||= current_ability.can?(:take_for_free, @recording)
  end

  def can_purchase?
    @can_purchase ||= current_ability.can?(:purchase, @recording)
  end

  def charge_amount
    @recording.purchase_price.to_f
  end

  private

  # NOTE: - it is present here because it can not be part of
  # after-session reconciliation because VODs are bought after its run
  def assign_revenue_to_organizer(payment_transaction)
    @recording.organizer.presenter.issued_presenter_credits.create!(amount: earnings_from_member,
                                                                    type: IssuedPresenterCredit::Types::EARNED_CREDIT)

    @recording.organizer.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                                  abstract_session: @recording,
                                                  data: {},
                                                  amount: earnings_from_member,
                                                  payment_transaction: payment_transaction)
  end

  def earnings_from_member
    revenue_split = @recording.organizer.revenue_percent / 100.0
    ((@recording.purchase_price - @recording.service_fee) * revenue_split).round(2)
  end

  def obtain_access
    @recording.recording_members.find_or_create_by!(participant: @participant, status: 'confirmed')

    @success_message = 'You have purchased access to Upload Video.'
    true
  rescue ActiveRecord::RecordInvalid => e
    @error_message = e.message
    false
  end

  def notify_user(payment_transaction_id)
    RecordingMailer.you_obtained_access(@recording.id, @current_user.id, payment_transaction_id).deliver_later
    true
  end
end
