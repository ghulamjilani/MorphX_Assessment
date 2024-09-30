# frozen_string_literal: true

module Api
  module V1
    module Webhook
      module Partner
        class SubscriptionsController < ::Api::V1::Webhook::Partner::ApplicationController
          before_action :authorization_only_for_organization

          def create
            render(:show) and return if partner_plan.blank?

            if %w[completed processing].include?(params[:status])
              create_or_activate_subscription
            else
              deactivate_subscription
            end

            render :show
          end

          private

          def partner_plan
            @partner_plan ||= ::Partner::Plan.joins(free_plan: :channel)
                                             .where(channels: { organization_id: current_organization.id })
                                             .find_by(foreign_plan_id: params.require(:plan_id))
          end

          def create_or_activate_subscription
            ::Partner::Subscription.transaction do
              unless (@partner_subscription = partner_plan.partner_subscriptions.find_by(partner_subscription_params))
                unless (user = ::User.find_by(email: customer_params[:email]))
                  user = ::User.invite!(customer_params.slice(:email, :first_name, :last_name), partner_plan.organization.user) do |u|
                    u.before_create_generic_callbacks_and_skip_validation
                    u.skip_invitation = true
                  end
                end
                free_subscription = ::FreeSubscription.create!(partner_plan.free_plan.free_subscription_params.merge(user: user))
                @partner_subscription = @partner_plan.partner_subscriptions.new(partner_subscription_params)
                @partner_subscription.free_subscription = free_subscription
                @partner_subscription.save!
              end
              @partner_subscription.active!
            end
          end

          def deactivate_subscription
            @partner_subscription = @partner_plan.partner_subscriptions.find_by(partner_subscription_params)
            @partner_subscription.inactive! if @partner_subscription&.active?
          end

          # Only allow a list of trusted parameters through.
          def partner_subscription_params
            {
              foreign_subscription_id: params.require(:subscription_id),
              foreign_customer_id: customer_params[:id],
              foreign_customer_email: customer_params[:email]
            }
          end

          def customer_params
            params.require(:customer).permit(:id, :email, :first_name, :last_name)
          end
        end
      end
    end
  end
end
