# frozen_string_literal: true

class FreeSubscriptionsMailerPreview < ApplicationMailerPreview
  def invite
    subscription = FreeSubscription.order('RANDOM()').first
    raise 'No subscription found, unable to show a preview' unless subscription

    FreeSubscriptionsMailer.invite(subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def going_to_be_finished
    subscription = FreeSubscription.order('RANDOM()').first
    raise 'No subscription found, unable to show a preview' unless subscription

    FreeSubscriptionsMailer.going_to_be_finished(subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def ended
    subscription = FreeSubscription.order('RANDOM()').first
    raise 'No subscription found, unable to show a preview' unless subscription

    FreeSubscriptionsMailer.ended(subscription.id)
  rescue StandardError => e
    fallback_mail(e)
  end
end
