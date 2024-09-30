# frozen_string_literal: true

class Api::V1::User::PaymentTransactionsController < Api::V1::ApplicationController
  def index
    @payment_transactions = current_user.payment_transactions
    if params[:purchased_item_id].present? && params[:purchased_item_type].present?
      @payment_transactions = @payment_transactions.where(purchased_item_id: params[:purchased_item_id].to_i,
                                                          purchased_item_type: params[:purchased_item_type])
    end
    @count = @payment_transactions.count
    @payment_transactions = @payment_transactions.order(checked_at: :desc).limit(@limit).offset(@offset)
  end
end
