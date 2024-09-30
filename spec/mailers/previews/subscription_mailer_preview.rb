# frozen_string_literal: true

class SubscriptionMailerPreview < ApplicationMailerPreview
  def channel_subscribed
    subscription = StripeDb::Subscription.order(Arel.sql('random()')).limit(1).first
    raise 'No StripeDb::Subscription found, unable to show a preview' unless subscription

    SubscriptionMailer.channel_subscribed(subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def channel_subscription_receipt
    log_transaction = LogTransaction.where(type: LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION)
                                    .order(Arel.sql('random()')).limit(1).first
    raise 'No LogTransaction found, unable to show a preview' unless log_transaction

    SubscriptionMailer.channel_subscription_receipt(log_transaction.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def gift_subscription
    log_transaction = LogTransaction.where(type: LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION)
                                    .order(Arel.sql('random()')).limit(1).first
    raise 'No LogTransaction found, unable to show a preview' unless log_transaction

    SubscriptionMailer.gift_subscription(log_transaction.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_received_gift_subscription
    log_transaction = LogTransaction.where(type: LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION)
                                    .order(Arel.sql('random()')).limit(1).first
    user = User.order(Arel.sql('random()')).limit(1).first
    raise 'No LogTransaction found, unable to show a preview' unless log_transaction

    SubscriptionMailer.you_received_gift_subscription(log_transaction.id, user.id)
  rescue StandardError => e
    fallback_mail(e)
  end
end
