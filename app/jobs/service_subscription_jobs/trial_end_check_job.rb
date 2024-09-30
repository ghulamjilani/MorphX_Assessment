# frozen_string_literal: true

class ServiceSubscriptionJobs::TrialEndCheckJob < ApplicationJob
  def perform
    StripeDb::ServiceSubscription.where(service_status: :trial, trial_end_notification_sent: false).find_each do |subscription|
      Rails.logger.info "Checking trial subscription #{subscription.id}"
      if subscription.current_period_end <= 1.day.from_now
        subscription.update(trial_end_notification_sent: true)
        ServiceSubscriptionsMailer.trial_will_end_soon(subscription.id).deliver_later
      end
    end
  end
end
