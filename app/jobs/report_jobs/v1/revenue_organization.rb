# frozen_string_literal: true

class ReportJobs::V1::RevenueOrganization < ApplicationJob
  sidekiq_options queue: 'low'

  def perform(id, klass = nil)
    report =  case klass
              when 'PaymentTransaction'
                pt = PaymentTransaction.find(id)
                channel = case pt.purchased_item
                          when Session, Recording, Booking::BookingPrice, Document
                            pt.purchased_item.channel
                          when StripeDb::Subscription
                            pt.purchased_item.channel_subscription.channel
                          when StripeDb::ServicePlan
                            # this is service subscription
                            nil
                          end
                if channel.present?
                  Reports::V1::RevenueOrganization.find_or_create_by!(organization_id: channel.organization_id,
                                                                      channel_id: channel.id, date: pt.created_at.to_date)
                end
              else
                Reports::V1::RevenueOrganization.find(id)
              end
    return unless report

    report.calculate
    report.save!
  end
end
