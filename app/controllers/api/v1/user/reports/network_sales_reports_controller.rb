# frozen_string_literal: true

module Api
  module V1
    module User
      module Reports
        class NetworkSalesReportsController < Api::V1::User::ApplicationController
          def index
            render_json(404, 'No organization found') and return if !current_user.platform_owner? && current_user.current_organization.blank?
            render_json(403, 'Access Denied') and return if !current_user.platform_owner? && cannot?(:view_revenue_report, current_user.current_organization)

            date_from = params[:date_from].present? ? Date.parse(params[:date_from].to_s) : nil
            date_to = Date.parse((params[:date_to] || Time.zone.today).to_s)
            channels = if current_user.platform_owner?
                         ::Channel.joins(organization: :user).where(fake: false, organizations: { fake: false }, users: { fake: false })
                       else
                         current_user.organization_channels_with_credentials(current_user.current_organization, :view_revenue_report)
                       end

            channels = channels.where(id: params[:channel_ids]) if params[:channel_ids].present?
            channels = channels.where(organization_id: params[:organization_ids]) if params[:organization_ids].present?
            channel_ids = channels.pluck(:id)
            organization_ids = channels.pluck(:organization_id).compact.uniq

            @reports = ::Reports::V1::RevenuePurchasedItem.group_by_period(date_from: date_from,
                                                                           date_to: date_to,
                                                                           organization_ids: organization_ids,
                                                                           channel_ids: channel_ids).to_a

            respond_to do |format|
              format.json
              format.csv do
                file = CSV.generate(headers: true) do |csv|
                  csv << [
                    'Channel',
                    'Product Type',
                    'Content',
                    'Creator/Host',
                    'Cost $',
                    'Number',
                    'Gross Income $',
                    'Platform Commission $ (Rev Share)',
                    'Income $',
                    'Refund $',
                    'Refund Platform $',
                    'Refund Owner $',
                    'Owner\'s Income $'
                  ]
                  @reports.each do |report|
                    channel = Channel.find_by(id: report[:_id][:channel_id])
                    item = report[:_id][:purchased_item_type].classify.constantize.find_by(id: report[:_id][:purchased_item_id])
                    creator = case report[:_id][:purchased_item_type]
                              when 'Session'
                                item.presenter&.user
                              when 'Video'
                                item.user
                              when 'Recording'
                                item.channel&.organization&.user
                              end

                    csv << [
                      channel.title,
                      ::Reports::V1::RevenuePurchasedItem::FORMATTED_TYPES[report[:_id][:type].to_sym],
                      item&.title || item&.im_name,
                      creator&.public_display_name,
                      report[:_id][:cost].to_i / 100.0,
                      report[:qty],
                      report[:gross_income].to_i / 100.0,
                      report[:commission].to_i / 100.0,
                      report[:income].to_i / 100.0,
                      report[:refund].to_i / 100.0,
                      report[:refund_system].to_i / 100.0,
                      report[:refund_creator].to_i / 100.0,
                      report[:total].to_i / 100.0
                    ]
                  end
                end

                filename = 'network_sales_report.csv'

                send_data file, filename: filename
              end
            end
          end
        end
      end
    end
  end
end
