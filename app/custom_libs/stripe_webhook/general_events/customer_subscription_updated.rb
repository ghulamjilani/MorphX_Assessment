# frozen_string_literal: true

class StripeWebhook::GeneralEvents::CustomerSubscriptionUpdated < StripeWebhook::Base
  @event_type = 'customer.subscription.updated'

  def perform
    if StripeDb::Subscription.exists?(stripe_id: @event.data.object.id)
      StripeDb::Subscription.create_or_update_from_stripe(@event.data.object.id)
    elsif StripeDb::ServiceSubscription.exists?(stripe_id: @event.data.object.id)
      StripeDb::ServiceSubscription.create_or_update_from_stripe(@event.data.object.id)
    else
      @logger.info("Stripe Subscription does not exist', parameters: #{@event.to_json}")
    end
  end
end
