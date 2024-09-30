# frozen_string_literal: true

class ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob < ApplicationJob
  def perform(subscription_id)
    subscription = StripeDb::ServiceSubscription.find(subscription_id)

    # check if there's any active subscription
    return if StripeDb::ServiceSubscription.exists?(organization_id: subscription.organization.id,
                                                    service_status: %w[new trial trial_suspended active grace suspended pending_deactivation])

    organization_memberships = subscription.organization.organization_memberships.where(status: OrganizationMembership::Statuses::PENDING)
    organization_memberships.find_each do |om|
      # invalidate cache for this
      # app/presenters/blocking_notification_presenter.rb#pending_user_invites
      Rails.cache.delete("pending_user_invites/#{om.user.cache_key}")
    end
    organization_memberships.update_all(status: OrganizationMembership::Statuses::CANCELLED)
  end
end
