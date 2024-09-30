# frozen_string_literal: true

class ServiceSubscriptionJobs::SuspendedCheckJob < ApplicationJob
  def perform
    StripeDb::ServiceSubscription.where(service_status: :suspended).find_each do |subscription|
      Rails.logger.info "Checking suspended subscription #{subscription.id}"
      subscription.update(suspended_at: Time.zone.now) if subscription.suspended_at.nil?
      suspended_days = subscription.feature_parameters.by_code(:suspended_days).first&.value || 3
      if ((subscription.suspended_at || subscription.updated_at) + suspended_days.to_i.days).past?
        subscription.deactivate!
        # ServiceSubscriptionJobs::RemoveContentJob.perform_async(subscription.id)
      end
    end
  end
end
