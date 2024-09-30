# frozen_string_literal: true

class StripeWebhook::GeneralEvents::ChargeFailed < StripeWebhook::Base
  @event_type = 'charge.failed'

  def perform
    charge = @event.data.object

    customer = User.find_by(stripe_customer_id: charge.customer)
    unless customer
      @logger.info("Stripe webhook error: User not found. Charge ##{charge.id}. Event ##{@event.id}")
      return
    end

    invoice = Stripe::Invoice.retrieve(charge.invoice)

    if invoice.subscription
      stripe_subscription = Stripe::Subscription.retrieve(invoice.subscription)
      subscription = StripeDb::ServiceSubscription.find_by(stripe_id: stripe_subscription.id)
      StripeDb::ServiceSubscription.create_or_update_from_stripe(subscription.stripe_id) if subscription
    end
  end
end
