# frozen_string_literal: true

module Api
  module V1
    module User
      module Partner
        class SubscriptionsController < ::Api::V1::User::Partner::ApplicationController
          before_action :set_partner_subscription, only: %i[show update destroy]

          def index
            channels = current_user.organization_channels_with_credentials(current_user.current_organization, :manage_channel_partner_subscriptions).pluck(:id)
            channels = channels.where(id: params[:channel_ids]) if params[:channel_ids].present?
            @partner_subscriptions = ::Partner::Subscription.joins(:partner_plan).where(partner_plans: { channel: channels })
          end

          def show
          end

          def update
            @partner_subscription.update(update_subscription_params)

            render :show
          end

          def destroy
            @partner_subscription.update(stopped_at: Time.now.utc, status: :inactive)

            render :show
          end

          private

          def set_partner_subscription
            @partner_subscription = ::Partner::Subscription.find(params[:id])
            raise AccessForbiddenError unless can?(:manage_partner_subscriptions, @partner_subscription.channel)

            @partner_subscription
          end

          def update_subscription_params
            params.permit(:status)
          end
        end
      end
    end
  end
end
