# frozen_string_literal: true

class Affiliate::Everflow::TrackPaymentTransactionJob < ApplicationJob
  def perform(payment_transaction_id, everflow_transaction_id)
    return unless Rails.application.credentials.backend[:initialize][:everflow][:enabled]

    payment_transaction = PaymentTransaction.find(payment_transaction_id)

    return if payment_transaction.affiliate_everflow_tracked_payment.present?

    everflow_transaction = payment_transaction.user.affiliate_everflow_transactions.find_by(id: everflow_transaction_id)

    if everflow_transaction.blank?
      Airbrake.notify('Affiliate::Everflow::TrackPaymentTransactionJob no everflow_transaction', parameters: {
                        payment_transaction_id: payment_transaction.id,
                        everflow_transaction_id: everflow_transaction_id
                      })

      return
    end

    purchased_item = case payment_transaction.purchased_item_type
                     when 'StripeDb::ServiceSubscription', 'StripeDb::Subscription'
                       payment_transaction.purchased_item
                     else
                       raise 'Not Implemented'
                       # payment_transaction.purchased_item
                     end

    if purchased_item.blank?
      Airbrake.notify('Affiliate::Everflow::TrackPaymentTransactionJob no purchased_item', parameters: {
                        everflow_transaction_id: everflow_transaction.id,
                        payment_transaction_id: payment_transaction.id
                      })

      return
    end

    url = "https://#{Rails.application.credentials.backend[:initialize][:everflow][:postback_domain]}/?nid=#{Rails.application.credentials.backend[:initialize][:everflow][:network_id]}&transaction_id=#{everflow_transaction.transaction_id}&amount=#{payment_transaction.total_amount / 100.0}&email=#{everflow_transaction.user.email}&order_id=#{payment_transaction.id}"
    if Rails.application.credentials.backend[:initialize][:everflow][:event_id].present?
      url += "&event_id=#{Rails.application.credentials.backend[:initialize][:everflow][:event_id]}"
    end
    resp = Excon.post(url)
    if [200, 204].include?(resp.status)
      payment_transaction.create_affiliate_everflow_tracked_payment(
        conversion_id: resp.headers['x-conversion-id'],
        purchased_item: purchased_item,
        affiliate_everflow_transaction_id: everflow_transaction.id
      )
    else
      Airbrake.notify('Affiliate::Everflow::TrackPaymentTransactionJob failed to track', parameters: {
                        everflow_transaction_id: everflow_transaction.id,
                        purchased_item_id: purchased_item.id,
                        purchased_item_type: purchased_item.class.name,
                        payment_transaction_id: payment_transaction.id
                      })
    end
  end
end
