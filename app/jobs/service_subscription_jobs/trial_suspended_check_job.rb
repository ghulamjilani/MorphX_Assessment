# frozen_string_literal: true

class ServiceSubscriptionJobs::TrialSuspendedCheckJob < ApplicationJob
  def perform
    StripeDb::ServiceSubscription.where(service_status: :trial_suspended).find_each do |subscription|
      Rails.logger.info "Checking trial suspended subscription #{subscription.id}"
      subscription.update(trial_suspended_at: Time.zone.now) if subscription.trial_suspended_at.nil?
      suspended_days = subscription.feature_parameters.by_code(:trial_suspended_days).first&.value || 3
      if ((subscription.trial_suspended_at || subscription.updated_at) + suspended_days.to_i.days).past?
        subscription.deactivate!
      end
    end
  end
end
