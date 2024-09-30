# frozen_string_literal: true

class Stripe::ServiceSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def update
    @subscription = StripeDb::ServiceSubscription.find(params[:id])
    if params[:cancel_trial].present?
      if @subscription.status != 'trialing'
        flash[:error] = 'The subscription is already not trial'
      else
        Stripe::Subscription.update(@subscription.stripe_id, { trial_end: 'now' })
        flash[:success] = 'Successfully activated!'
      end
    end
    redirect_back fallback_location: root_path
  end

  def destroy
    @subscription = StripeDb::ServiceSubscription.find(params[:id])
    Stripe::Subscription.update(@subscription.stripe_id, { cancel_at_period_end: true })
    end_of_period = DateTime.strptime(@subscription.stripe_item.current_period_end.to_s,
                                      '%s').in_time_zone(current_user.timezone).strftime('%d %b %I:%M %p %Z')
    flash[:success] = "Successfully unsubscribed! Subscription will be closed at the end of period: #{end_of_period}"
    redirect_back fallback_location: root_path
  end
end
