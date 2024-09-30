# frozen_string_literal: true

module Api
  module V1
    module User
      class ChannelFreeSubscriptionsController < Api::V1::ApplicationController
        def index
          @free_subscriptions = current_user.free_subscriptions.in_action
          @count = @free_subscriptions.count
          @free_subscriptions = @free_subscriptions.limit(@limit).offset(@offset)
        end

        def show
          @free_subscription = current_user.free_subscriptions.find(params[:id])
        end
      end
    end
  end
end
