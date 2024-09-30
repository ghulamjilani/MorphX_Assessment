# frozen_string_literal: true

module Api
  module V1
    module User
      module Reports
        class ChannelsController < Api::V1::User::ApplicationController
          def index
            render_json(404, 'No organization found') and return if !current_user.platform_owner? && current_user.current_organization.blank?
            render_json(403, 'Access Denied') and return if !current_user.platform_owner? && cannot?(:view_revenue_report, current_user.current_organization)

            query = if current_user.platform_owner?
                      organization_ids = params[:organization_ids] || ::Reports::V1::RevenuePurchasedItem.organization_ids
                      ::Channel.where(organization_id: organization_ids)
                    else
                      current_user.organization_channels_with_credentials(current_user.current_organization, :view_revenue_report)
                    end

            query = query.where('channels.title ILIKE ?', "%#{params[:name]}%") if params[:name].present?
            @count = query.count
            @channels = query.order(title: :asc).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
