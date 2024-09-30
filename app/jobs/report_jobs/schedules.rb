# frozen_string_literal: true

class ReportJobs::Schedules < ApplicationJob
  sidekiq_options queue: 'low'

  # FIXME: for now we get all channels, but we should find lists channel only with transaction
  def perform(*_args)
    generate_revenue_organization_report
  end

  def generate_revenue_organization_report
    # Generate all Reports once
    unless Reports::V1::RevenueOrganization.count.positive?
      Channel.find_each do |c|
        (c.created_at.to_date..Date.today).each do |date|
          report = Reports::V1::RevenueOrganization.find_or_create_by!(organization_id: c.organization_id,
                                                                       channel_id: c.id, date: date)
          ReportJobs::V1::RevenueOrganization.perform_async(report.id)
        end
      end
    end

    Channel.find_each do |c|
      date = Date.today
      report = Reports::V1::RevenueOrganization.find_or_create_by!(organization_id: c.organization_id,
                                                                   channel_id: c.id, date: date)
      ReportJobs::V1::RevenueOrganization.perform_async(report.id)
    end
  end
end
