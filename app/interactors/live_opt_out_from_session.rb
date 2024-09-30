# frozen_string_literal: true

# NOTE: - this interactor is used for opting out as immersive and livestream user
class LiveOptOutFromSession
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper

  def initialize(session, current_user)
    @session            = session
    @current_user       = current_user
    @refund_coefficient = BraintreeRefundCoefficient.new(@session)
  end

  def opt_out_without_money_refund
    remove_from_members do
      if payment_transaction.present?
        refund_amount = if @success_message == I18n.t('sessions.opted_out_success.when_co_presenter')
                          payment_transaction.total_amount.to_f
                        else
                          payment_transaction.total_amount.to_f * @refund_coefficient.coefficient
                        end

        if refund_amount.positive?
          payment_transaction.system_credit_refund!(refund_amount / 100)
        else
          Rails.logger.info 'too late for refunds'
        end
      elsif system_credit_transaction.present?
        system_credit_transaction.system_credit_refund!(system_credit_transaction.amount)
      else
        Rails.logger.info 'not eligible for refund'
      end

      @session.organizer_abstract_session_pay_promises.where(co_presenter_id: @current_user.presenter_id).destroy_all
    end
  end

  def opt_out_and_get_money_refund
    remove_from_members do
      raise "Operation not permitted, #{inspect}" if system_credit_transaction.present?

      payment_transaction.money_refund!
    end
  end

  attr_reader :success_message

  private

  # @param - mandatory block of code that is executed after user is removed from session members
  def remove_from_members
    raise 'missing accounting-processing *after-update* block' unless block_given?

    ActiveRecord::Base.transaction do
      participant_id = @current_user.try(:participant).try(:id)
      presenter_id   = @current_user.try(:presenter).try(:id)

      if @session.session_participations.where(participant_id: participant_id).destroy_all.present?
        @success_message  = I18n.t('sessions.opted_out_success.when_participant')
        @transaction_type = TransactionTypes::IMMERSIVE
      end

      if @session.session_co_presenterships.where(presenter_id: presenter_id).destroy_all.present?
        @success_message  = I18n.t('sessions.opted_out_success.when_co_presenter')
        @transaction_type = TransactionTypes::IMMERSIVE
      end

      if @session.livestreamers.where(participant_id: participant_id).destroy_all.present?
        @success_message  = I18n.t('sessions.opted_out_success.when_livestream')
        @transaction_type = TransactionTypes::LIVESTREAM
      end

      @session.session_invited_immersive_participantships.where(participant_id: participant_id).destroy_all
      @session.session_invited_livestream_participantships.where(participant_id: participant_id).destroy_all
      @session.session_invited_immersive_co_presenterships.where(presenter_id: presenter_id).destroy_all

      yield

      # NOTE: you don't even need to cleanup organizer_abstract_session_pay_promises because we
      #      check room members(this co-presenter won't be able to attend the session)

      @session.payment_transactions
              .not_failed
              .where(user_id: @current_user.id)
              .update_all({ archived: true })

      @session.system_credit_entries
              .where(participant_id: @current_user.participant_id)
              .update_all({ archived: true })

      CheckSessionWaitingList.perform_async(@session.id)

      @current_user.invalidate_nearest_abstract_session_cache
      @current_user.invalidate_purchased_session_cache(@session.id)
      @current_user.touch
      @session.touch
    end
  end

  def transaction_type
    @transaction_type or raise 'does not have type'
  end

  def payment_transaction
    @payment_transaction ||= @session.payment_transactions.where(type: transaction_type).not_failed.where(user_id: @current_user.id).last
  end

  def system_credit_transaction
    @system_credit_transaction ||= SystemCreditEntry.where(commercial_document: @session,
                                                           participant_id: @current_user.participant_id, type: transaction_type, archived: false).last
  end
end
