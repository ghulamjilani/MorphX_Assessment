# frozen_string_literal: true

class Dashboard::MoneyController < Dashboard::ApplicationController
  before_action :setup_pagination

  def earnings
    return redirect_to purchases_dashboard_money_index_url if current_user.current_organization.blank?

    order = params[:order].presence || :desc
    order_type = %w[big small].include?(params[:order]) ? 'amount' : 'created_at'
    order = (order == 'big') ? :desc : :asc if order_type == 'amount'

    query = current_user.current_organization.organizer.earnings.joins(%(INNER JOIN payment_transactions ON payment_transactions.id = log_transactions.payment_transaction_id AND log_transactions.payment_transaction_type = 'PaymentTransaction'))
    if params[:start_at_from].present? || params[:start_at_to].present?
      from = begin
        DateTime.strptime(params[:start_at_from], '%m/%d/%Y')
      rescue StandardError
        nil
      end
      to = begin
        DateTime.strptime(params[:start_at_to], '%m/%d/%Y')
      rescue StandardError
        nil
      end
      if from.present? && to.present?
        query = query.where(log_transactions: { created_at: from..to.end_of_day })
      elsif from.present?
        query = query.where('log_transactions.created_at >= ?', from)
      elsif to.present?
        query = query.where('log_transactions.created_at <=', to.end_of_day)
      end
    end
    query = query.where(payment_transactions: { payout_status: params[:status].to_i }) if params[:status].present?
    @log_transactions = query.reorder("#{order_type}": order).page(params[:page]).per(@per_page)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def payouts
    @payouts = current_user.current_organization.organizer.payouts.order(created_at: :desc).page(params[:page]).per(@per_page)
  end

  def products_earnings
  end

  def purchases
    @log_transactions = current_user.log_transactions
                                    .where.not(type: [LogTransaction::Types::NET_INCOME,
                                                      LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION,
                                                      LogTransaction::Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION])
                                    .order(created_at: :desc).page(params[:page]).per(@per_page)
  end

  def my_subscriptions
    @subscriptions = current_user.channels_subscriptions.order(created_at: :desc).page(params[:page]).per(@per_page)
  end

  private

  def setup_pagination
    @per_page = (params[:per_page] || 20).to_i
    @per_page = (@per_page > 20) ? 20 : @per_page
  end
end
