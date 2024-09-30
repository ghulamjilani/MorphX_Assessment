# frozen_string_literal: true

namespace :payment_transactions do
  desc 'Move Plan association to Subscription'
  task update_plan_associations: :environment do
    PaymentTransaction.where(purchased_item_type: 'StripeDb::Plan').find_each do |pt|
      next unless pt.purchased_item

      subscription = pt.purchased_item.stripe_subscriptions.where(user_id: pt.user_id, stripe_plan_id: pt.purchased_item_id).order(created_at: :desc).limit(1).first
      if subscription.present?
        pt.purchased_item = subscription
        pt.save
      else
        puts "Unable to update channel subscription transaction #{pt.id}"
      end
    end
    PaymentTransaction.where(purchased_item_type: 'StripeDb::ServicePlan').find_each do |pt|
      next unless pt.purchased_item

      subscription = pt.purchased_item.service_subscriptions.where(user_id: pt.user_id, stripe_plan_id: pt.purchased_item_id).order(created_at: :desc).limit(1).first
      if subscription.present?
        pt.purchased_item = subscription
        pt.save
      else
        puts "Unable to update business subscription transaction #{pt.id}"
      end
    end
  end
end
