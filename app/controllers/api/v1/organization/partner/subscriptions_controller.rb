# frozen_string_literal: true

module Api
  module V1
    module Organization
      module Partner
        class SubscriptionsController < ::Api::V1::Organization::Partner::ApplicationController
          def index
            @partner_subscriptions = current_organization.partner_subscriptions
            @partner_subscriptions = @partner_subscriptions.where(foreign_subscription_id: params[:foreign_subscription_id]) if params[:foreign_subscription_id].present?
            @partner_subscriptions = @partner_subscriptions.where(partner_plan_id: params[:partner_plan_id]) if params[:partner_plan_id].present?
            @partner_subscriptions = @partner_subscriptions.where(free_subscription_id: params[:free_subscription_id]) if params[:free_subscription_id].present?
            @partner_subscriptions = @partner_subscriptions.where(foreign_customer_email: params[:foreign_customer_email]) if params[:foreign_customer_email].present?

            @count = @partner_subscriptions.count
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @partner_subscriptions = @partner_subscriptions.order(Arel.sql("created_at #{order}"))
          end

          private

          def authorization_only_for_organization
            render_json 401, 'Only organization can get access here' if current_organization.blank?
          end
        end
      end
    end
  end
end
