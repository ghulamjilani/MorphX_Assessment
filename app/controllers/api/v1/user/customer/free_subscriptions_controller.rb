# frozen_string_literal: true

module Api
  module V1
    module User
      module Customer
        class FreeSubscriptionsController < Api::V1::User::Customer::ApplicationController
          def index
            @free_subscriptions = current_user.free_subscriptions.in_action

            order_by = %w[created_at start_at end_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'

            @count = @free_subscriptions.count
            @free_subscriptions = @free_subscriptions.includes(:channel, :organization, :free_plan)
                                                     .order(Arel.sql("#{order_by} #{order}"))
                                                     .limit(@limit)
                                                     .offset(@offset)
          end
        end
      end
    end
  end
end
