# frozen_string_literal: true

class ObtainRecordedAccessToSession
  extend ActiveSupport::Concern

  include ActsAsSessionObtainable

  def initialize(session, current_user)
    @session = session
    @current_user = current_user

    # otherwise "obtain access to free session" CTA scenario for a new user would fail
    if @current_user.present? && @current_user.participant.blank?
      @current_user.create_participant!
    end

    @participant = current_user.try(:participant)
  end

  # TODO: - FIXME _not_pending_invitee is unnecessary
  def could_be_obtained_and_not_pending_invitee?
    could_be_obtained?
  end

  # This method is used only in view templates
  def could_be_obtained?
    could_be_purchased? || can_take_for_free?
  end

  def execute(params = {})
    if params[:discount]
      @discount = Discount.find_by(name: params[:discount])
      @discount = nil unless @discount&.valid_for?(@session, 'Replay', @current_user)
    end
    if params[:stripe_token] || params[:stripe_card]
      execute_stripe(params[:stripe_token] || params[:stripe_card], params)
    elsif params[:provider] == 'paypal'
      execute_paypal(params)
    else
      execute_system_credit
    end
    true
  end

  def execute_system_credit
    if charge_amount.zero?
      unless can_take_for_free?
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_recorded_access_with_system_credit, @session)
        raise 'not allowed'
      end

      system_credit_entry = create_system_credit_transaction(TransactionTypes::RECORDED)

      entry = Plutus::Entry.new(
        description: "Sold VOD session - #{@session.always_present_title}",
        commercial_document: system_credit_entry,
        debits: [
          { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: @session.recorded_purchase_price },
          { account_name: Accounts::COGS::RECORDED_SESSION_VENDOR_EARNINGS, amount: earnings_from_vod_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDED_SESSION_REVENUE,
            amount: (@session.recorded_purchase_price - @session.recorded_service_fee) },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @session.recorded_service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_vod_member }
        ]
      )
      entry.save!

    end

    return false if @error_message.present?

    obtain_recorded_access

    return false if @error_message.present?

    unless charge_amount.zero?
      assign_revenue_to_organizer(system_credit_entry)
    end
    notify_user(nil)
  end

  def execute_stripe(token, params = {})
    if charge_amount.zero?
      unless can_take_for_free?
        raise 'not allowed'
      end

      payment_transaction = nil
    else
      unless current_ability.can?(:purchase_recorded_access, @session)
        raise 'not allowed'
      end

      payment_transaction = create_stripe_transaction(TransactionTypes::RECORDED, token, params)

      return false if payment_transaction == false

      @discount&.discount_usages&.create(user: @current_user)
      charge = Stripe::Charge.retrieve(payment_transaction.pid)
      transaction = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
      fee = begin
        (transaction.fee / 100.0).round(2)
      rescue StandardError
        0
      end
      tax = (payment_transaction.tax_cents / 100.0).round(2)

      entry = Plutus::Entry.new(
        description: "Sold VOD session - [stripe] - #{@session.always_present_title}",
        commercial_document: payment_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.amount / 100.0).round(2) + tax },
          { account_name: Accounts::COGS::RECORDED_SESSION_VENDOR_EARNINGS, amount: earnings_from_vod_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDED_SESSION_REVENUE,
            amount: (payment_transaction.amount / 100.0) - @session.recorded_service_fee - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @session.recorded_service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_vod_member }
        ]
      )
      entry.save!

      if payment_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s }
      elsif payment_transaction.paypal?
        data = { paypal_payment_id: payment_transaction.pid, paypal_payer_email: payment_transaction.payer_email }
      else
        raise "unknown payment type: #{payment_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_RECORDED_SESSION,
                                             abstract_session: @session,
                                             image_url: payment_transaction.image_url,
                                             data: data,
                                             amount: -payment_transaction.total_amount / 100.0,
                                             payment_transaction: payment_transaction)
    end

    return false if @error_message.present?

    obtain_recorded_access

    return false if @error_message.present?

    unless charge_amount.zero?
      assign_revenue_to_organizer(payment_transaction)
    end

    notify_user(payment_transaction.try(:id))
  end

  def execute_paypal(params = {})
    raise 'no info provided' if params.empty?

    if charge_amount.zero?
      unless can_take_for_free?
        raise 'not allowed'
      end

      payment_transaction = nil
    else
      unless current_ability.can?(:purchase_recorded_access, @session)
        raise 'not allowed'
      end

      payment_transaction = create_paypal_transaction(TransactionTypes::RECORDED, params)

      return false if payment_transaction == false

      @discount&.discount_usages&.create(user: @current_user)
      begin
        sale = PayPal::SDK::REST::DataTypes::Sale.find(payment_transaction.pid)
        fee = sale.transaction_fee.value.to_f
      rescue StandardError
        fee = 0
      end
      tax = (payment_transaction.tax_cents / 100.0).round(2)

      entry = Plutus::Entry.new(
        description: "Sold VOD session - [paypal] - #{@session.always_present_title}",
        commercial_document: payment_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.amount / 100.0).round(2) + tax },
          { account_name: Accounts::COGS::RECORDED_SESSION_VENDOR_EARNINGS, amount: earnings_from_vod_member }
        ],
        credits: [
          { account_name: Accounts::Income::RECORDED_SESSION_REVENUE,
            amount: (payment_transaction.amount / 100.0) - @session.recorded_service_fee - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax },
          { account_name: Accounts::Income::SERVICE_FEES, amount: @session.recorded_service_fee },
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: earnings_from_vod_member }
        ]
      )
      entry.save!

      if payment_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s }
      elsif payment_transaction.paypal?
        data = { paypal_payment_id: payment_transaction.pid, paypal_payer_email: payment_transaction.payer_email }
      else
        raise "unknown payment type: #{payment_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_RECORDED_SESSION,
                                             abstract_session: @session,
                                             image_url: payment_transaction.image_url,
                                             data: data,
                                             amount: -payment_transaction.total_amount / 100.0,
                                             payment_transaction: payment_transaction)
    end

    return false if @error_message.present?

    obtain_recorded_access

    return false if @error_message.present?

    unless charge_amount.zero?
      assign_revenue_to_organizer(payment_transaction)
    end

    notify_user(payment_transaction.try(:id))
  end

  def obtain_non_free_access_title
    "Watch #{as_currency charge_amount, @current_user}"
  end

  def can_take_for_free?
    @can_take_for_free ||= current_ability.can?(:obtain_recorded_access_to_free_session, @session)
  end

  def can_have_free_trial?
    false
  end

  def could_be_purchased?
    @could_be_purchased ||= current_ability.cannot?(:access_replay_as_subscriber, @session) &&
                            current_ability.can?(:purchase_recorded_access, @session)
  end

  def can_take_as_subscriber?
    @can_take_as_subscriber ||= current_ability.can?(:access_replay_as_subscriber, @session)
  end

  def charge_amount
    @session.recorded_purchase_price.to_f
  end

  private

  def earnings_from_vod_member
    revenue_split = @session.organization.user.revenue_percent / 100.0

    ((@session.recorded_purchase_price - discount_amount - @session.recorded_service_fee) * revenue_split).round(2)
  end

  # NOTE: - it is present here because it can not be part of
  # after-session reconciliation because VODs are bought after its run
  def assign_revenue_to_organizer(payment_transaction)
    @session.organization.user.presenter.issued_presenter_credits.create!(amount: earnings_from_vod_member,
                                                                          type: IssuedPresenterCredit::Types::EARNED_CREDIT)

    @session.organization.user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                                        abstract_session: @session,
                                                        data: { type: :replay },
                                                        amount: earnings_from_vod_member,
                                                        payment_transaction: payment_transaction)
  end

  def obtain_recorded_access
    @session.recorded_members.find_or_create_by!(participant: @participant, status: 'confirmed')

    @success_message = I18n.t('interactors.obtained_vod_access')
    true
  rescue ActiveRecord::RecordInvalid => e
    @error_message = e.message
    false
  end

  def notify_user(payment_transaction_id)
    SessionMailer.you_obtained_recorded_access(@session.id, @current_user.id, payment_transaction_id).deliver_later
    true
  end
end
