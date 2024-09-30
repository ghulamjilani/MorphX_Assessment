# frozen_string_literal: true

# Alex call it after-session-reconciliation
class SessionAccounting < ApplicationJob
  def perform(session_id)
    @session = Session.find(session_id)
    @current_user = @session.organization.user

    unless @session.finished?
      message = "can not run accounting job for not finished session - #{@session.id}"
      Rails.logger.info message

      if Rails.env.development? # because otherwise db:seed fails #TODO - is there a better way?
        return
      end

      if Rails.env.qa? || Rails.env.production?
        raise message
        return
      end
    end

    if @session.cancelled?
      Rails.logger.info "session #{@session.id} is cancelled, skipping after-session-reconciliation"
      return
    end

    execute_co_presenter_pay_promises
    cogs_reimbursement_fee_collection
    execute_live_participants
    record_todo_attendance_achievements
  end

  private

  def record_todo_attendance_achievements
    @session.session_participations.each do |sp|
      TodoAchievement.find_or_create_by(type: TodoAchievement::Types::PARTICIPATE_IN_A_SESSION,
                                        user: sp.participant.user)
    end

    @session.livestreamers.each do |l|
      TodoAchievement.find_or_create_by(type: TodoAchievement::Types::PARTICIPATE_IN_A_SESSION,
                                        user: l.participant.user)
    end
  end

  def cogs_reimbursement_fee_collection
    # session fee is charged here in after-session-reconciliation and not during session creation
    # because if session is cancelled, session fee is not applied

    if @session.immersive_delivery_method? && @session.immersive_purchase_price.positive?
      @session.session_participations.where(free_trial: false).each do |_particiption|
        # user = particiption.participant.user
        # payment_transaction = user.payment_transactions.not_failed.where(purchased_item: @session, type: TransactionTypes::IMMERSIVE).first
        # puts "@session.immersive_purchase_price #{@session.immersive_purchase_price}"
        # puts "revenue_split #{revenue_split}"

        debits = [
          { account_name: Accounts::COGS::IMMERSIVE_SESSION_VENDOR_EARNINGS,
            amount: (@session.immersive_purchase_price * revenue_split).round(2) }
        ]
        credits = [
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE,
            amount: (@session.immersive_purchase_price * revenue_split).round(2) }
        ]
        entry = Plutus::Entry.new(
          description: 'COGS reimbursement immersive fee collection',
          commercial_document: @session,
          debits: debits,
          credits: credits
        )
        begin
          entry.save!
        rescue ActiveRecord::RecordInvalid => e
          puts e
          Airbrake.notify_sync(e,
                               parameters: {
                                 session: @session.inspect,
                                 debits: debits,
                                 credits: credits,
                                 entry: entry.inspect
                               })
        end
      end
    end

    if @session.livestream_delivery_method? && @session.livestream_access_cost.positive?
      @session.livestreamers.where(free_trial: false).each do |_livestreamer|
        # user = livestreamer.participant.user
        # payment_transaction = user.payment_transactions.not_failed.where(purchased_item: @session, type: TransactionTypes::LIVESTREAM).first
        debits = [
          { account_name: Accounts::COGS::LIVESTREAM_SESSION_VENDOR_EARNINGS,
            amount: (@session.livestream_purchase_price * revenue_split).round(2) }
        ]
        credits = [
          { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE,
            amount: (@session.livestream_purchase_price * revenue_split).round(2) }
        ]

        entry = Plutus::Entry.new(description: 'COGS reimbursement livestream fee collection',
                                  commercial_document: @session,
                                  debits: debits,
                                  credits: credits)
        begin
          entry.save!
        rescue ActiveRecord::RecordInvalid => e
          Airbrake.notify_sync(e,
                               parameters: {
                                 session: @session.inspect,
                                 debits: debits,
                                 credits: credits,
                                 entry: entry.inspect
                               })
        end
      end
    end
  end

  def revenue_split
    @current_user.revenue_percent / 100.0
  end

  def execute_live_participants
    if @session.immersive_delivery_method? && @session.booking.present?
      earnings_from_paid_immersive_participants = 0
      payment_transaction = @session.booking.payment_transaction

      if payment_transaction
        amount = (payment_transaction.amount * revenue_split / 100.0).round(2)
        earnings_from_paid_immersive_participants += amount
        @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                               abstract_session: @session,
                                               data: { access_type: :immersive },
                                               amount: amount,
                                               payment_transaction: payment_transaction)
        payment_transaction.refunds.each do |refund|
          data = {
            transaction_id: payment_transaction.pid,
            status: refund.status,
            credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
            refund: true
          }
          refund_amount = if payment_transaction.stripe?
                            -refund.amount
                          elsif payment_transaction.paypal?
                            -(refund.amount.total.to_f * 100).to_i
                          end
          @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                                 abstract_session: payment_transaction.purchased_item,
                                                 data: data,
                                                 amount: (refund_amount / 100.0 * @current_user.revenue_percent) / 100.0,
                                                 payment_transaction: payment_transaction)
        end
      end
    elsif @session.immersive_delivery_method? && @session.immersive_purchase_price.positive?
      earnings_from_paid_immersive_participants = 0
      @session.session_participations.where(free_trial: false).each do |sp|
        payment_transaction = sp.user.payment_transactions.success.not_archived.find_by(type: :immersive_access,
                                                                                        purchased_item: @session)
        next unless payment_transaction

        # We need to check each payment transaction amount because of discounts
        amount = (payment_transaction.amount * revenue_split / 100.0).round(2)
        earnings_from_paid_immersive_participants += amount
        @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                               abstract_session: @session,
                                               data: { access_type: :immersive },
                                               amount: amount,
                                               payment_transaction: payment_transaction)

        # create refund logs
        payment_transaction.refunds.each do |refund|
          data = {
            transaction_id: payment_transaction.pid,
            status: refund.status,
            credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
            refund: true
          }
          refund_amount = if payment_transaction.stripe?
                            -refund.amount
                          elsif payment_transaction.paypal?
                            -(refund.amount.total.to_f * 100).to_i
                          end
          @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                                 abstract_session: payment_transaction.purchased_item,
                                                 data: data,
                                                 amount: (refund_amount / 100.0 * @current_user.revenue_percent) / 100.0,
                                                 payment_transaction: payment_transaction)
        end
      end
    else
      earnings_from_paid_immersive_participants = 0
    end

    if @session.livestream_delivery_method? && @session.livestream_purchase_price.positive?
      earnings_from_paid_livestream_participants = 0
      @session.livestreamers.where(free_trial: false).each do |sp|
        payment_transaction = sp.user.payment_transactions.success.not_archived.find_by(type: :livestream_access,
                                                                                        purchased_item: @session)
        next unless payment_transaction

        # We need to check each payment transaction amount because of discounts
        amount = (payment_transaction.amount * revenue_split / 100.0).round(2)
        earnings_from_paid_livestream_participants += amount
        @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                               abstract_session: @session,
                                               data: { access_type: :livestream },
                                               amount: amount,
                                               payment_transaction: payment_transaction)
        # create refund logs
        payment_transaction.refunds.each do |refund|
          data = {
            transaction_id: payment_transaction.pid,
            status: refund.status,
            credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
            refund: true
          }
          @current_user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                                 abstract_session: payment_transaction.purchased_item,
                                                 data: data,
                                                 amount: (-refund.amount / 100.0 * @current_user.revenue_percent) / 100.0,
                                                 payment_transaction: payment_transaction)
        end
      end
    else
      earnings_from_paid_livestream_participants = 0
    end

    net_profit = earnings_from_paid_immersive_participants + earnings_from_paid_livestream_participants

    return unless net_profit.positive?

    net_profit = net_profit.round(2)

    @current_user.presenter.issued_presenter_credits.create!(amount: net_profit,
                                                             type: IssuedPresenterCredit::Types::EARNED_CREDIT)
  end

  def execute_co_presenter_pay_promises
    @session.organizer_abstract_session_pay_promises.each do |organizer_session_pay_promise|
      co_presenter = organizer_session_pay_promise.co_presenter

      # if somehow user paid for himself
      next if @session.payment_transactions.where(user: co_presenter.user).not_archived.success.present?

      begin
        @current_user.presenter.presenter_credit_entries.create!(
          amount: SystemParameter.co_presenter_fee.to_f,
          description: "Paying for co-presenter(pay promises) - #{co_presenter.user.public_display_name} - #{@session.always_present_title}"
        )

        entry = Plutus::Entry.new(
          description: 'Paying for co-presenter(pay promise)',
          commercial_document: @session,
          debits: [
            { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE,
              amount: SystemParameter.co_presenter_fee.to_f.round(2) }
          ],
          credits: [
            { account_name: Accounts::Income::MISCELLANEOUS_FEES,
              amount: SystemParameter.co_presenter_fee.to_f.round(2) }
          ]
        )
        entry.save!

        @current_user.log_transactions.create!(type: LogTransaction::Types::PAID_FOR_CO_PRESENTER,
                                               abstract_session: @session,
                                               data: { presenter_id: co_presenter.id },
                                               amount: (-SystemParameter.co_presenter_fee.to_f).round(2))

        Rails.logger.info "substract #{SystemParameter.co_presenter_fee.to_f} from organizer's credit line because of pay promise to #{co_presenter.inspect}"
      rescue StandardError => e
        # include important debug info if this ever fails(immediate action/manual investigation is required)
        Airbrake.notify_sync(RuntimeError.new(e.message),
                             parameters: {
                               session_id: @session.id,
                               organizer_session_pay_promise_id: organizer_session_pay_promise.id
                             })
        raise e
      end
    end
  end
end
