# frozen_string_literal: true

class VodOptOutFromSession
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
        refund_amount = payment_transaction.total_amount.to_f * @refund_coefficient.coefficient

        if refund_amount.positive?
          payment_transaction.system_credit_refund!(refund_amount)
        else
          Rails.logger.info 'too late for refunds'
        end
      elsif system_credit_transaction.present?
        system_credit_transaction.system_credit_refund!(system_credit_transaction.amount)
      else
        raise "can not opt out #{inspect}"
      end
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

      if @session.recorded_members.where(participant_id: participant_id).destroy_all.present?
        @success_message  = I18n.t('sessions.opted_out_success.when_recorded_member')
        @transaction_type = TransactionTypes::RECORDED
      end

      yield

      # NOTE: you don't even need to cleanup organizer_abstract_session_pay_promises because we
      #      check room members(this co-presenter won't be able to attend the session)

      @session.touch
    end
  end

  def transaction_type
    @transaction_type or raise 'does not have type'
  end

  def payment_transaction
    @payment_transaction ||= @session.payment_transactions.where(type: transaction_type).success.where(user_id: @current_user.id).last
  end

  def system_credit_transaction
    @system_credit_transaction ||= SystemCreditEntry.where(participant_id: @current_user.participant_id,
                                                           commercial_document: @session, type: transaction_type).last
  end
end
