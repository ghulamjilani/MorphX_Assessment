# frozen_string_literal: true

class ServiceSubscriptionJobs::GraceCheckJob < ApplicationJob
  def perform
    StripeDb::ServiceSubscription.where(service_status: :grace).find_each do |subscription|
      Rails.logger.info "Checking grace subscription #{subscription.id}"
      subscription.update(grace_at: Time.zone.now) if subscription.grace_at.nil?
      grace_days = subscription.feature_parameters.by_code(:grace_days).first&.value || 3
      if ((subscription.grace_at || subscription.updated_at) + grace_days.to_i.days).past?
        subscription.suspended!
        # elsif ((Time.now.utc.beginning_of_day - subscription.grace_at.utc.beginning_of_day).to_i / 60 / 60 / 24 % 7).zero?
        # Resend email each 7 days
        # ServiceSubscriptionsMailer.grace_started_payment_failed(subscription.id).deliver_later
      end
    end
  end
end
