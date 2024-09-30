# frozen_string_literal: true

class ServiceSubscriptionsMailerPreview < ApplicationMailerPreview
  def receipt
    log_transaction = LogTransaction.where(type: LogTransaction::Types::PURCHASED_SERVICE_SUBSCRIPTION)
                                    .order(Arel.sql('random()')).first
    raise 'No LogTransaction found, unable to show a preview' unless log_transaction

    ServiceSubscriptionsMailer.receipt(log_transaction.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def trial_started
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.trial_started(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def trial_ended
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.trial_ended(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def activated
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.activated(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def cancellation_requested
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.cancellation_requested(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def canceled
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.canceled(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def trial_finished_payment_failed
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.trial_finished_payment_failed(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def grace_started_payment_failed
    service_subscription = StripeDb::ServiceSubscription.order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.grace_started_payment_failed(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def suspended_started
    service_subscription = StripeDb::ServiceSubscription.where.not(suspended_at: nil).order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.suspended_started(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def deactivated
    service_subscription = StripeDb::ServiceSubscription.where.not(suspended_at: nil).where.not(current_period_end: nil).order(Arel.sql('random()')).first
    raise 'No ServiceSubscription found, unable to show a preview' unless service_subscription

    ServiceSubscriptionsMailer.deactivated(service_subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end
end
