# frozen_string_literal: true

class PendingRefundsController < ApplicationController
  before_action :authenticate_user!
  before_action :get_pending_refund

  # NOTE: reasons for pending refunds:
  #      1)session cancelled         - you're still its member(for history) before and after using pending refund
  #      2)opting out from session   - you're not its member already before using pending refund
  #      3)declined changed Start At - you're still its member before using pending refund
  #
  #      see #remove_yourself_from_abstract_session_if_needed where we handle 3)'s cleanup/removing user from that abstract session

  def get_money
    authorize!(:reimburse_refund, @pending_refund)

    payment_transaction = @pending_refund.payment_transaction
    payment_transaction.money_refund!
    @pending_refund.destroy!

    remove_yourself_from_abstract_session_if_needed

    flash[:success] = 'Refund receipt has been sent'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  def get_system_credit
    authorize!(:reimburse_refund, @pending_refund)

    if @pending_refund.payment_transaction.present?
      payment_transaction = @pending_refund.payment_transaction
      payment_transaction.system_credit_refund!(@pending_refund.amount)
      @pending_refund.destroy!
    else
      raise "can not interpret - #{@pending_refund.inspect}"
    end

    remove_yourself_from_abstract_session_if_needed

    flash[:success] = 'Refund receipt has been sent'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::PendingRefundAbility.new(current_user)
  end

  def get_pending_refund
    @pending_refund = current_user.pending_refunds.where(id: params[:id]).last
    if @pending_refund.blank?
      flash[:notice] = I18n.t('controllers.pending_refunds.invalid_or_outdated_request_message')
      redirect_back fallback_location: dashboard_path
    end
  end

  # @see "NOTE" described in the header that explains what kind of important cleanup/processing is done here
  def remove_yourself_from_abstract_session_if_needed
    abstract_session = @pending_refund.abstract_session

    return if abstract_session.cancelled? # skip cleanup, it is 1)'s case

    participant_id = current_user.try(:participant).try(:id)
    presenter_id   = current_user.try(:presenter).try(:id)

    if abstract_session.is_a?(Session)
      abstract_session.session_participations.where(participant_id: participant_id).destroy_all
      abstract_session.livestreamers.where(participant_id: participant_id).destroy_all
      abstract_session.session_co_presenterships.where(presenter_id: presenter_id).destroy_all

      abstract_session.session_invited_immersive_participantships.where(participant_id: participant_id).destroy_all
      abstract_session.session_invited_livestream_participantships.where(participant_id: participant_id).destroy_all
      abstract_session.session_invited_immersive_co_presenterships.where(presenter_id: presenter_id).destroy_all
    else
      raise "can not interpret #{inspect}"
    end
  end
end
