# frozen_string_literal: true

class PayoutJob < ApplicationJob
  def perform
    reference = "#{Rails.application.credentials.global[:service_name]} Payout from #{Time.now.to_date}"
    date_to = if Time.now.day > 5
                Date.new(Time.now.year, Time.now.month, 5)
              else
                Date.new(Time.now.year, (Time.now.month - 1), 20)
              end.to_datetime.end_of_day
    transactions_by_user = LogTransaction.select(:user_id, 'sum(log_transactions.amount) as total_amount')
                                         .joins(%(INNER JOIN payment_transactions ON payment_transactions.id = log_transactions.payment_transaction_id AND log_transactions.payment_transaction_type = 'PaymentTransaction'))
                                         .where('log_transactions.created_at <= ?', date_to).where(payment_transactions: { payout_status: 0 }, type: %w[
                                                                                                     net_income sold_channel_subscription sold_channel_gift_subscription
                                                                                                   ])
                                         .group(:user_id).reorder(:user_id)
    transactions_by_user.each do |ltu|
      lt_ids = LogTransaction.select(:id).where('log_transactions.created_at <= ?', date_to).where(
        user_id: ltu.user_id, type: %w[net_income sold_channel_subscription sold_channel_gift_subscription]
      ).map(&:id)

      # outdate all previous payouts
      Payout.where(user_id: ltu.user_id, status: :pending).update_all(status: :outdated)

      payout = Payout.create(
        user_id: ltu.user_id,
        amount_cents: (ltu.total_amount * 100).to_i,
        amount_currency: 'USD',
        reference: reference,
        provider: :stripe,
        status: :pending
      )
      payment_transactions = PaymentTransaction.joins(:log_transactions).where(log_transactions: { id: lt_ids })
      payment_transactions.update_all(payout_id: payout.id)
    end
  end
end
