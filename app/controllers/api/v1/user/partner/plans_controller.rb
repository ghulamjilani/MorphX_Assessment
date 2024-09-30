# frozen_string_literal: true

module Api
  module V1
    module User
      module Partner
        class PlansController < ::Api::V1::User::Partner::ApplicationController
          before_action :set_partner_plan, only: %i[show update destroy]

          def create
            render :show
          end

          def show
          end

          def update
            render :show
          end

          def destroy
            render :show
          end

          private

          def set_partner_plan
            @partner_plan = Partner::Plan.find(params[:id])
            raise AccessForbiddenError unless can?(:manage_channel_partner_subscriptions, @partner_plan.channel)

            @partner_plan
          end

          def current_ability
            @current_ability ||= AbilityLib::ChannelAbility.new(current_user)
          end
        end
      end
    end
  end
end
