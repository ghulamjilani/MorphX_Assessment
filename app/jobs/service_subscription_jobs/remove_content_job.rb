# frozen_string_literal: true

class ServiceSubscriptionJobs::RemoveContentJob < ApplicationJob
  def perform(subscription_id)
    subscription = StripeDb::ServiceSubscription.find(subscription_id)

    # check if there's any active subscription
    return if StripeDb::ServiceSubscription.exists?(organization_id: subscription.organization.id,
                                                    service_status: %w[new trial trial_suspended active grace
                                                                       suspended pending_deactivation])

    channels = subscription.organization.channels
    channels.each do |channel|
      # clean recordings
      recordings = channel.recordings
      recordings.each { |r| r.touch(:deleted_at) }
      # clean replays
      videos = channel.videos
      videos.find_each { |v| v.touch(:deleted_at) }
      # cancel sessions
      sessions = channel.sessions.upcoming.not_cancelled
      reason = AbstractSessionCancelReason.find_or_create_by(name: 'Business Subscription deactivated')
      sessions.each do |session|
        interactor = SessionCancellation.new(session, reason)
        interactor.execute
      end
      # cancel subscriptions
      channel.subscription.stripe_subscriptions.where.not(status: :canceled).find_each do |s|
        s.stripe_item.cancel_at_period_end = true
        s.stripe_item.save
      end
    end
  end
end
