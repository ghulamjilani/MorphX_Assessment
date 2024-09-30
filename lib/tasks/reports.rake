# frozen_string_literal: true

namespace :reports do
  desc 'Create reports'
  task generate: :environment do
    from = PaymentTransaction.order(created_at: :asc).first.created_at.to_date
    (from..Time.zone.today.to_date).each do |date|
      PaymentTransaction.success_and_refund
                        .select(:purchased_item_id, :purchased_item_type, :type)
                        .joins(:log_transactions)
                        .where(log_transactions: { created_at: date.all_day })
                        .group(:purchased_item_id, :purchased_item_type, :type).order(nil).each do |pt|
        channel = case pt.purchased_item
                  when Session, Recording, Booking::BookingPrice, Document
                    pt.purchased_item&.channel
                  when StripeDb::Subscription
                    pt.purchased_item&.channel_subscription&.channel
                  when StripeDb::ServiceSubscription
                    # this is service subscription
                    nil
                  end

        if channel.blank?
          puts "Empty channel: #{pt.id} #{pt.type} --- #{pt.purchased_item_type} #{pt.purchased_item_id}"
          next
        end

        purchased_item = if pt.type == 'recorded'
                           pt.purchased_item.records.first
                         elsif pt.purchased_item.is_a?(StripeDb::Subscription)
                           pt.purchased_item.stripe_plan
                         else
                           pt.purchased_item
                         end

        if purchased_item.blank?
          puts "Empty purchased item: #{pt.id} #{pt.type} --- #{pt.purchased_item_type} #{pt.purchased_item_id}"
          next
        end

        type = pt.type == 'channel_gift_subscription' ? 'channel_subscription' : pt.type

        report = Reports::V1::RevenuePurchasedItem.find_or_create_by!(organization_id: channel.organization_id,
                                                                      channel_id: channel.id,
                                                                      purchased_item_type: purchased_item.class.name,
                                                                      purchased_item_id: purchased_item.id,
                                                                      type: type,
                                                                      date: date)
        begin
          report.calculate!
        rescue StandardError => e
          puts e.message
        end
      end
    end
  end
end
