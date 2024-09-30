# frozen_string_literal: true

class ObtainLivestreamAccessToSession
  extend ActiveSupport::Concern

  include ActsAsSessionObtainable

  def initialize(session, current_user)
    @session = session
    @current_user = current_user
    @free_type_is_chosen = nil

    # otherwise "obtain access to free session" CTA scenario for a new user would fail
    if @current_user.present? && @current_user.participant.blank?
      @current_user.create_participant!
    end

    @participant = current_user.try(:participant)
  end

  # This method is used only in view templates and prevents "IMMERSS ME" buttons from being visible
  # while user has not accepted/rejected invitation to that session.
  def could_be_obtained_and_not_pending_invitee?
    @could_be_obtained_and_not_pending_invitee ||= lambda do
      return false if pending_invitee?

      can_have_free_trial? || can_take_for_free? || could_be_purchased?
    end.call
  end

  # This method is used only in "purchase preview" page
  # it ignore whether user is invited or not because we need to display enrollment options here
  def could_be_obtained?
    can_have_free_trial? || can_take_for_free? || could_be_purchased?
  end

  def execute(params = {})
    if params[:discount]
      @discount = Discount.find_by(name: params[:discount])
      @discount = nil unless @discount&.valid_for?(@session, 'Livestream', @current_user)
    end
    if params[:stripe_token] || params[:stripe_card]
      execute_stripe(params[:stripe_token] || params[:stripe_card], params)
    elsif params[:provider] == 'paypal'
      execute_paypal(params)
    elsif @free_type_is_chosen
      execute_free
    else
      execute_system_credit
    end
    @discount&.discount_usages&.create(user: @current_user)
    true
  end

  def execute_system_credit
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    # when user has subscription we often have error, so lets skip all access validations for subscriber
    # https://immerss.airbrake.io/projects/135202/groups/2334971197193855137?tab=notice-detail
    if has_subscription?
      system_credit_entry = nil
    elsif @session.livestream_free || charge_amount.zero?
      if !current_ability.can?(:obtain_free_trial_livestream_access, @session) &&
         !current_ability.can?(:obtain_livestream_access_to_free_session, @session) &&
         !has_subscription?
        raise 'not allowed'
      end

      system_credit_entry = nil
    else
      unless current_ability.can?(:purchase_livestream_access_with_system_credit, @session)
        raise 'not allowed'
      end

      system_credit_entry = create_system_credit_transaction(TransactionTypes::LIVESTREAM)
    end

    return false if @error_message.present?

    add_to_livestreamers

    if system_credit_entry.present?
      perform_ledger_accounting_for_participant(nil, system_credit_entry)
    end

    return false if @error_message.present?

    @current_user.touch
    @session.touch

    notify_user(nil, system_credit_entry.try(:id))
  end

  def execute_stripe(token = nil, params = {})
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    if @session.livestream_free || charge_amount.zero?
      stripe_transaction = nil

      if !current_ability.can?(:obtain_free_trial_livestream_access,
                               @session) && !current_ability.can?(:obtain_livestream_access_to_free_session, @session)
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_livestream_access, @session)
        raise 'not allowed'
      end

      stripe_transaction = create_stripe_transaction(TransactionTypes::LIVESTREAM, token, params)

      return false if stripe_transaction == false
    end

    return false if @error_message.present?

    add_to_livestreamers

    if stripe_transaction.present?
      perform_ledger_accounting_for_participant(stripe_transaction, nil)
    end

    return false if @error_message.present?

    @current_user.touch
    @session.touch

    notify_user(stripe_transaction.try(:id), nil)
  end

  def execute_paypal(params = {})
    raise 'no info provided' if params.empty?
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    if @session.livestream_free || charge_amount.zero?
      paypal_transaction = nil

      if !current_ability.can?(:obtain_free_trial_livestream_access,
                               @session) && !current_ability.can?(:obtain_livestream_access_to_free_session, @session)
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_livestream_access, @session)
        raise 'not allowed'
      end

      paypal_transaction = create_paypal_transaction(TransactionTypes::LIVESTREAM, params)

      return false if paypal_transaction == false
    end

    return false if @error_message.present?

    add_to_livestreamers

    if paypal_transaction.present?
      perform_ledger_accounting_for_participant(paypal_transaction, nil)
    end

    return false if @error_message.present?

    @current_user.touch
    @session.touch

    notify_user(paypal_transaction.try(:id), nil)
  end

  def has_subscription?
    @has_subscription ||= current_ability.can?(:access_as_subscriber, @session)
  end

  def can_take_for_free?
    @can_take_for_free ||= current_ability.can?(:obtain_livestream_access_to_free_session, @session)
  end

  def can_have_free_trial?
    @can_have_free_trial ||= current_ability.can?(:obtain_free_trial_livestream_access, @session)
  end

  def could_be_purchased?
    @could_be_purchased ||= current_ability.can?(:purchase_livestream_access, @session)
  end

  def charge_amount
    return 0.0 if @session.livestream_free # fixes #1402

    # because at that point type is not set yet(user may still choose)
    on_preview_purchase_page = @free_type_is_chosen.nil? && could_be_purchased?
    if on_preview_purchase_page
      charge_amount_on_preview_purchase
    else
      charge_amount_when_type_is_set
    end
  end

  private

  def execute_free
    if !@session.session_participations.find_by(participant_id: @current_user.participant_id) &&
       @session.livestream_purchase_price.present?
      add_to_livestreamers
    end
  end

  def charge_amount_on_preview_purchase
    @session.livestream_purchase_price.to_f.tap { |x| raise "#{x.inspect} has to be non-zero" if x.zero? }
  end

  def charge_amount_when_type_is_set
    if current_ability.can?(:obtain_free_trial_livestream_access, @session) && @free_type_is_chosen
      return 0.0
    end

    @session.livestream_purchase_price.to_f
  end

  # @param payment_transaction - could be nil
  # @param system_credit_entry - could be nil
  def perform_ledger_accounting_for_participant(payment_transaction, system_credit_entry)
    if payment_transaction.present?
      tax = (payment_transaction.tax_cents / 100.0).round(2)
      if payment_transaction.stripe?
        charge = Stripe::Charge.retrieve(payment_transaction.pid)
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
      else
        begin
          sale = PayPal::SDK::REST::DataTypes::Sale.find(payment_transaction.pid)
          fee = sale.transaction_fee.value.to_f
        rescue StandardError
          fee = 0
        end
      end
      entry = Plutus::Entry.new(
        description: "Sold livestream session - [#{payment_transaction.provider}] - #{@session.always_present_title}",
        commercial_document: payment_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.amount / 100.0) + tax }
        ],
        credits: [
          { account_name: Accounts::Income::LIVESTREAM_SESSION_REVENUE,
            amount: (payment_transaction.amount / 100.0) - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax }
        ]
      )
      entry.save!

      if payment_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
                 card_type: payment_transaction.card_type, charge_id: payment_transaction.pid }
      elsif payment_transaction.paypal?
        data = { paypal_payment_id: payment_transaction.pid, paypal_payer_email: payment_transaction.payer_email }
      else
        raise "unknown payment type: #{payment_transaction.inspect}"
      end

      @current_user.log_transactions.create!(
        type: LogTransaction::Types::PURCHASED_LIVESTREAM_SESSION,
        abstract_session: @session,
        image_url: payment_transaction.image_url,
        data: data,
        amount: -payment_transaction.total_amount / 100.0,
        payment_transaction: payment_transaction
      )
    elsif system_credit_entry.present?
      entry = Plutus::Entry.new(
        description: "Sold livestream session to participant - #{@session.always_present_title}",
        commercial_document: system_credit_entry,
        debits: [
          { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: system_credit_entry.amount }
        ],
        credits: [
          { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: system_credit_entry.amount }
        ]
      )
      entry.save!

      @current_user.log_transactions.create!(
        type: LogTransaction::Types::PURCHASED_LIVESTREAM_SESSION_VIA_SYSTEM_CREDIT,
        abstract_session: @session,
        data: {},
        amount: -system_credit_entry.amount,
        payment_transaction: system_credit_entry
      )
    else
      raise "can not interpret in performing ledger accounting #{inspect}"
    end
  end

  def add_to_livestreamers
    invited_as_co_presenter = @current_user.presenter.present? && @session.session_invited_immersive_co_presenterships.where(presenter: @current_user.presenter).pending.present?
    if invited_as_co_presenter
      raise 'can not obtain livestream access with pending co-presenter invitation'
    end

    as_free_trial = current_ability.can?(:obtain_free_trial_livestream_access, @session) && @free_type_is_chosen

    unless @session.livestreamers.find_by(participant: @participant)
      begin
        @session.livestreamers.create!(participant: @participant, free_trial: as_free_trial)
      rescue ActiveRecord::RecordNotUnique => e
        nil
      end
    end

    immersive_participation = @session.session_invited_immersive_participantships.where(participant: @participant).pending.first
    immersive_participation.accept! if immersive_participation.present?

    livestream_participation = @session.session_invited_livestream_participantships.where(participant: @participant).pending.first
    livestream_participation.accept! if livestream_participation.present?

    @success_message = I18n.t('interactors.obtained_livestream_access')
    true
  rescue ActiveRecord::RecordInvalid => e
    @error_message = e.message
    false
  end

  def notify_user(payment_transaction_id, system_credit_entry_id)
    SessionMailer.you_obtained_live_access(@session.id, @current_user.id, payment_transaction_id,
                                           system_credit_entry_id).deliver_later

    CombinedNotificationSetting.perform_with_notice_count(
      ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
      @session.organization.user, @session
    ) do |_total_participants_num|
      Immerss::SessionMultiFormatMailer.new.purchases_summary_for_organizer(@session.id).deliver
    end
    true
  end
end
