# frozen_string_literal: true

class ObtainImmersiveAccessToSession
  extend ActiveSupport::Concern

  include ActsAsSessionObtainable

  # @param free_type_is_chosen [Boolean] free_type_is_chosen indicates which type of obtaining is chosen(when there is such choice): paid of free_trial
  def initialize(session, current_user)
    @session = session
    @current_user = current_user
    @free_type_is_chosen = nil

    # otherwise "obtain access to free session" CTA scenario for a new user would fail
    if @current_user.present? && @current_user.participant.blank?
      @current_user.create_participant!
    end

    @participant = current_user.try(:participant)
    @presenter = current_user.try(:presenter)
  end

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
      @discount = nil unless @discount&.valid_for?(@session, 'Immersive', @current_user)
    end
    if params[:stripe_token] || params[:stripe_card]
      execute_stripe(params[:stripe_token] || params[:stripe_card], params)
    elsif params[:provider] == 'paypal'
      execute_paypal(params)
    else
      execute_system_credit
    end
    @discount&.discount_usages&.create(user: @current_user)
    true
  end

  def execute_system_credit
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    if @session.immersive_free || charge_amount.zero?
      if !current_ability.can?(:obtain_free_trial_immersive_access, @session) &&
         !current_ability.can?(:obtain_immersive_access_to_free_session, @session)
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_immersive_access_with_system_credit, @session, charge_amount)
        raise 'not allowed'
      end

      system_credit_entry = create_system_credit_transaction(TransactionTypes::IMMERSIVE)
    end

    return false if @error_message.present?

    add_to_members(nil, system_credit_entry)

    return false if @error_message.present?

    remove_from_waiting_list
    notify_organizer

    PurchaseReferralFeesAccounting.perform(@session.id, nil, system_credit_entry.try(:id))

    @current_user.touch

    notify_user(nil, system_credit_entry.try(:id))
  end

  def execute_stripe(token = nil, params = {})
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    if @session.immersive_free || charge_amount.zero?
      stripe_transaction = nil

      if !current_ability.can?(:obtain_free_trial_immersive_access,
                               @session) && !current_ability.can?(:obtain_immersive_access_to_free_session, @session)
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_immersive_access, @session)
        raise 'not allowed - looks like user opened several *preview purchase* pages in different browsers and it exceede max_number_of_immersive_participants'
      end

      stripe_transaction = create_stripe_transaction(TransactionTypes::IMMERSIVE, token, params)

      return false if stripe_transaction == false
    end

    return false if @error_message.present?

    add_to_members(stripe_transaction, nil)

    return false if @error_message.present?

    remove_from_waiting_list
    notify_organizer

    PurchaseReferralFeesAccounting.perform(@session.id, stripe_transaction.try(:id), nil)

    @current_user.touch

    notify_user(stripe_transaction.try(:id), nil)
  end

  # {
  # "payer_email"=>"buyer@my.unite.live",
  # "payer_id"=>"VJ2XUC7E4EDJN",
  # "payer_status"=>"VERIFIED",
  # "first_name"=>"Leila",
  # "last_name"=>"Forbes",
  # "address_name"=>"Leila Forbes",
  # "address_street"=>"1 Main St",
  # "address_city"=>"San Jose",
  # "address_state"=>"CA",
  # "address_country_code"=>"US",
  # "address_zip"=>"95131",
  # "residence_country"=>"US",
  # "txn_id"=>"78M99859E71941111",
  # "mc_currency"=>"USD",
  # "mc_fee"=>"1.14",
  # "mc_gross"=>"28.80",
  # "protection_eligibility"=>"ELIGIBLE",
  # "payment_fee"=>"1.14",
  # "payment_gross"=>"28.80",
  # "payment_status"=>"Completed",
  # "payment_type"=>"instant",
  # "item_name"=>"Tanoodle The Cathedral of Learning 258",
  # "item_number"=>"139",
  # "quantity"=>"1",
  # "txn_type"=>"web_accept",
  # "payment_date"=>"2018-06-14T10:44:35Z",
  # "business"=>"business@my.unite.live",
  # "receiver_id"=>"E8BYANWZ98RJU",
  # "notify_version"=>"UNVERSIONED",
  # "verify_sign"=>"A1lSYVRUw5Py-NhGaeWB17A4SqsIAujUuap1B1Meh.IfX59CKdOn-GUj",
  # "provider"=>"paypal",
  # "type"=>"paid_immersive",
  # "controller"=>"sessions",
  # "action"=>"confirm_purchase",
  # "channel_id"=>"9",
  # "id"=>"139"
  # }
  def execute_paypal(params = {})
    raise 'no info provided' if params.empty?
    raise 'type is not chosen' if @free_type_is_chosen.nil?

    if @session.immersive_free || charge_amount.zero?
      paypal_transaction = nil

      if !current_ability.can?(:obtain_free_trial_immersive_access, @session) && !current_ability.can?(:obtain_immersive_access_to_free_session, @session)
        raise 'not allowed'
      end
    else
      unless current_ability.can?(:purchase_immersive_access, @session)
        raise 'not allowed - looks like user opened several *preview purchase* pages in different browsers and it exceede max_number_of_immersive_participants'
      end

      paypal_transaction = create_paypal_transaction(TransactionTypes::IMMERSIVE, params)

      return false if paypal_transaction == false
    end

    return false if @error_message.present?

    add_to_members(paypal_transaction, nil)

    return false if @error_message.present?

    remove_from_waiting_list
    notify_organizer

    PurchaseReferralFeesAccounting.perform(@session.id, paypal_transaction.try(:id), nil)

    @current_user.touch

    notify_user(paypal_transaction.try(:id), nil)
  end

  def can_have_free_trial?
    @can_have_free_trial ||= current_ability.can?(:obtain_free_trial_immersive_access, @session)
  end

  def can_take_for_free?
    @can_take_for_free ||= current_ability.can?(:obtain_immersive_access_to_free_session, @session)
  end

  def could_be_purchased?
    @could_be_purchased ||= current_ability.can?(:purchase_immersive_access, @session)
  end

  def charge_amount
    return 0.0 if @session.immersive_free # fixes #1402

    # because at that point type is not set yet(user may still choose)
    on_preview_purchase_page = @free_type_is_chosen.nil? && could_be_purchased?
    if on_preview_purchase_page
      charge_amount_on_preview_purchase
    else
      charge_amount_when_type_is_set
    end
  end

  private

  def charge_amount_on_preview_purchase
    if type_of_user == :invited_co_presenter
      if @session.immersive_free || @session.livestream_free \
         || @session.requested_free_session_satisfied_at.present? \
         || (@session.immersive_purchase_price.present? && @session.immersive_purchase_price.zero?) \
         || (@session.livestream_purchase_price.present? && @session.livestream_purchase_price.zero?)

        0.0
      else
        SystemParameter.co_presenter_fee.to_f
      end
    else
      @session.immersive_purchase_price.to_f.tap { |x| raise "#{x.inspect} has to be non-zero" if x.zero? }
    end
  end

  def charge_amount_when_type_is_set
    if %i[voluntary_participant invited_participant].include?(type_of_user) &&
       (current_ability.can?(:obtain_free_trial_immersive_access, @session) ||
         current_ability.can?(:obtain_immersive_access_to_free_session, @session)) && @free_type_is_chosen
      return 0.0
    end

    if type_of_user == :invited_co_presenter
      if @session.immersive_free || @session.livestream_free \
         || @session.requested_free_session_satisfied_at.present? \
         || (@session.immersive_purchase_price.present? && @session.immersive_purchase_price.zero?) \
         || (@session.livestream_purchase_price.present? && @session.livestream_purchase_price.zero?)

        0.0
      else
        SystemParameter.co_presenter_fee.to_f
      end
    else
      @session.immersive_purchase_price.to_f
    end
  end

  def satisfies_max_number_of_immersive_participants?
    case type_of_user
    when :invited_co_presenter
      true
    when :voluntary_participant, :invited_participant
      @session.interactive_slots_available?
    end
  end

  # maybe this should include free/paid + participant/co-presenter switches as well
  def type_of_user
    @type_of_user ||= begin
      participant_id = @current_user.try(:participant).try(:id)
      presenter_id = @current_user.try(:presenter).try(:id)

      if @current_user.present? && @current_user.participant.present? && @session.session_invited_immersive_participantships.where(participant: @current_user.participant).pending.present?
        :invited_participant
      elsif @current_user.present? && @current_user.presenter.present? && @session.session_invited_immersive_co_presenterships.where(presenter: @current_user.presenter).pending.present?
        :invited_co_presenter
      else
        :voluntary_participant
      end
    end
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
        description: "Sold immersive session to participant - [#{payment_transaction.provider}] - #{@session.always_present_title}",
        commercial_document: payment_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.amount / 100.0).round(2) + tax }
        ],
        credits: [
          { account_name: Accounts::Income::IMMERSIVE_SESSION_REVENUE,
            amount: (payment_transaction.amount / 100.0) - fee },
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: fee },
          { account_name: Accounts::ShortTermLiability::SALES_TAX, amount: tax }
        ]
      )
      entry.save!

      if payment_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
                 card_type: payment_transaction.card_type }
      elsif payment_transaction.paypal?
        data = { paypal_payment_id: payment_transaction.pid, paypal_payer_email: payment_transaction.payer_email }
      else
        raise "unknown payment type: #{payment_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_INTERACTIVE_ABSTRACT_SESSION,
                                             abstract_session: @session,
                                             image_url: payment_transaction.image_url,
                                             data: data,
                                             amount: -payment_transaction.total_amount / 100.0,
                                             payment_transaction: payment_transaction)
    elsif system_credit_entry.present?
      entry = Plutus::Entry.new(
        description: "Sold immersive session to participant - #{@session.always_present_title}",
        commercial_document: system_credit_entry,
        debits: [
          { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: system_credit_entry.amount }
        ],
        credits: [
          { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: system_credit_entry.amount }
        ]
      )
      entry.save!

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_IMMERSIVE_ABSTRACT_SESSION_VIA_SYSTEM_CREDIT,
                                             abstract_session: @session,
                                             data: {},
                                             amount: -system_credit_entry.amount,
                                             payment_transaction: system_credit_entry)
    else
      raise "can not interpret in performing ledger accounting #{inspect}"
    end
  end

  # @param payment_transaction - could be nil
  # @param system_credit_entry - could be nil
  def perform_ledger_accounting_for_co_presenter(payment_transaction, system_credit_entry)
    if payment_transaction.present?
      entry = Plutus::Entry.new(
        description: "Sold immersive session to co-presenter - #{@session.always_present_title}",
        commercial_document: payment_transaction,
        debits: [
          { account_name: Accounts::Asset::MERCHANT, amount: payment_transaction.amount }
        ],
        credits: [
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: payment_transaction.amount }
        ]
      )
      entry.save!

      if payment_transaction.credit_card?
        data = { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
                 card_type: payment_transaction.card_type }
      elsif payment_transaction.paypal?
        data = { paypal_payment_id: payment_transaction.pid, paypal_payer_email: payment_transaction.payer_email }
      else
        raise "unknown payment type: #{payment_transaction.inspect}"
      end

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_INTERACTIVE_ABSTRACT_SESSION,
                                             abstract_session: @session,
                                             image_url: payment_transaction.image_url,
                                             data: data,
                                             amount: -payment_transaction.total_amount / 100.0,
                                             payment_transaction: payment_transaction)
    elsif system_credit_entry.present?
      entry = Plutus::Entry.new(
        description: "Sold immersive session to co-presenter - #{@session.always_present_title}",
        commercial_document: system_credit_entry,
        debits: [
          { account_name: Accounts::ShortTermLiability::ADVANCE_PURCHASE, amount: system_credit_entry.amount }
        ],
        credits: [
          { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: system_credit_entry.amount }
        ]
      )
      entry.save!

      @current_user.log_transactions.create!(type: LogTransaction::Types::PURCHASED_IMMERSIVE_ABSTRACT_SESSION_VIA_SYSTEM_CREDIT,
                                             abstract_session: @session,
                                             data: {},
                                             amount: -system_credit_entry.amount,
                                             payment_transaction: system_credit_entry)
    else
      raise "can not interpret in performing ledger accounting #{inspect}"
    end
  end

  # @param transaction - could be nil
  # @param system_credit_entry - could be nil
  def add_to_members(payment_transaction, system_credit_entry)
    case type_of_user
    when :invited_co_presenter

      begin
        @session.co_presenters << @presenter

        presentership = @session.session_invited_immersive_co_presenterships.where(presenter: @presenter).pending.first!
        presentership.accept!

        if payment_transaction.present? || system_credit_entry.present?
          # TODO: - pass system_credit_entry as well? low priority?
          perform_ledger_accounting_for_co_presenter(payment_transaction, system_credit_entry)
        end

        @success_message = I18n.t('interactors.invited_copresenter_obtained_immersive_access')
      rescue ActiveRecord::RecordInvalid => e
        @error_message = e.message
      end

    when :voluntary_participant
      begin
        if !@session.immersive_free && charge_amount.zero? && @session.free_trial_for_first_time_participants
          @session.session_participations.find_or_create_by!(participant: @participant, free_trial: true)
        else
          @session.session_participations.find_or_create_by!(participant: @participant)
        end

        if payment_transaction.present? || system_credit_entry.present?
          perform_ledger_accounting_for_participant(payment_transaction, system_credit_entry)
        end

        @success_message = I18n.t('interactors.voluntary_participant_obtained_immersive_access')
      rescue ActiveRecord::RecordInvalid => e
        @error_message = e.message
      end

    when :invited_participant

      begin
        if !@session.immersive_free && charge_amount.zero? && @session.free_trial_for_first_time_participants
          @session.session_participations.find_or_create_by!(participant: @participant, free_trial: true)
        else
          @session.session_participations.find_or_create_by!(participant: @participant)
        end

        immersive_participation = @session.session_invited_immersive_participantships.where(participant: @participant).pending.first!
        immersive_participation.accept!

        livestream_participation = @session.session_invited_immersive_participantships.where(participant: @participant).pending.first
        livestream_participation.reject! if livestream_participation.present?

        if system_credit_entry.present? || payment_transaction.present?
          perform_ledger_accounting_for_participant(payment_transaction, system_credit_entry)
        end

        @success_message = I18n.t('interactors.invited_participant_obtained_immersive_access')
      rescue ActiveRecord::RecordInvalid => e
        @error_message = e.message
      end
    else
      raise 'unknown type of user'
    end
  end

  def notify_organizer
    # temporarily disabling it for co-presenters
    # low priority(we have to update all 3 delivery methods!)
    return if type_of_user == :invited_co_presenter

    CombinedNotificationSetting
      .perform_with_notice_count(ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                                 @session.organizer,
                                 @session) do |_total_participants_num|
      Immerss::SessionMultiFormatMailer.new.purchases_summary_for_organizer(@session.id).deliver
    end
    true
  end

  def remove_from_waiting_list
    @session.remove_from_waiting_list(@current_user)
    true
  end

  def notify_user(transaction_id, system_credit_entry_id)
    SessionMailer.you_obtained_live_access(@session.id, @current_user.id, transaction_id,
                                           system_credit_entry_id).deliver_later
    true
  end
end
