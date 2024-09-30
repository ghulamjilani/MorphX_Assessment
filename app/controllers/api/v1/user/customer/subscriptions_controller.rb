# frozen_string_literal: true

module Api
  module V1
    module User
      module Customer
        class SubscriptionsController < Api::V1::User::Customer::ApplicationController
          def index
            @subscriptions = ::StripeDb::Subscription.joins(channel_subscription: :channel).where(subscriptions: { enabled: true }).where(user: current_user)

            @subscriptions = @subscriptions.where(status: params[:status]) if params[:status].present?
            @subscriptions = @subscriptions.where(subscriptions: { channel_id: params[:channel_id] }) if params[:channel_id].present?

            order_by = %w[created_at status canceled_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'

            @count = @subscriptions.count
            @subscriptions = @subscriptions.includes(:channel, :organization, :channel_subscription)
                                           .order(Arel.sql("stripe_subscriptions.#{order_by} #{order}"))
                                           .limit(@limit)
                                           .offset(@offset)
          end
        end
      end
    end
  end
end
