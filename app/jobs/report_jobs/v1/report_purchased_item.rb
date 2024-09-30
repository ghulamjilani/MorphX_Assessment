# frozen_string_literal: true

class ReportJobs::V1::ReportPurchasedItem < ApplicationJob
  sidekiq_options queue: 'low'

  def perform(id, klass = nil)
    report = case klass
             when 'PaymentTransaction'
               pt = PaymentTransaction.find(id)
               channel = case pt.purchased_item
                         when Session, Recording, Booking::BookingPrice, Document
                           pt.purchased_item.channel
                         when StripeDb::Subscription
                           pt.purchased_item.channel_subscription.channel
                         when StripeDb::ServiceSubscription
                           # this is service subscription
                           nil
                         end
               if channel.present?
                 purchased_item = if pt.type == 'recorded'
                                    pt.purchased_item.records.first
                                  elsif pt.purchased_item.is_a?(StripeDb::Subscription)
                                    pt.purchased_item.stripe_plan
                                  else
                                    pt.purchased_item
                                  end
                 type = pt.type == 'channel_gift_subscription' ? 'channel_subscription' : pt.type
                 Reports::V1::RevenuePurchasedItem.find_or_create_by!(organization_id: channel.organization_id,
                                                                      channel_id: channel.id,
                                                                      purchased_item_type: purchased_item.class.name,
                                                                      purchased_item_id: purchased_item.id,
                                                                      type: type,
                                                                      date: pt.created_at.to_date)
               end
             else
               Reports::V1::RevenuePurchasedItem.find_by(id: id)
             end
    return unless report

    report.calculate!
  end
end
