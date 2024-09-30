# frozen_string_literal: true

class ServiceSubscriptionJobs::SuspendedMailerJob < ApplicationJob
  def perform
    StripeDb::ServiceSubscription.where(service_status: :suspended).find_each do |subscription|
      # send message every day
      ServiceSubscriptionsMailer.suspended_started(subscription.id).deliver_now
    end
  end
end
