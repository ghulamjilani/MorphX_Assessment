# frozen_string_literal: true

envelope json do
  json.array! @payment_transactions do |payment_transaction|
    json.extract! payment_transaction, :id, :pid, :status, :credit_card_last_4, :card_type, :provider
    json.amount (payment_transaction.amount / 100.0).round(2)
    json.tax (payment_transaction.tax_cents / 100.0).round(2)
    json.total_amount (payment_transaction.total_amount / 100.0).round(2)
    json.checked_at payment_transaction.checked_at&.utc&.to_fs(:rfc3339)
    if params[:purchased_item_type] == 'StripeDb::ServiceSubscription'
      json.purchased_item_name payment_transaction.log_transactions.where(type: :purchased_service_subscription).first&.abstract_session&.nickname
    end
  end
end
