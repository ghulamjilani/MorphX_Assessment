# frozen_string_literal: true

module Api
  module V1
    module User
      module Feed
        class SessionsController < Api::V1::ApplicationController
          before_action :authorization_only_for_user

          def index
            query = current_user.feed_sessions

            query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?
            query = query.where(presenter_id: params[:presenter_id]) if params[:presenter_id].present?
            query = query.joins(:channel).where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?
            query = query.joins(:booking) if params[:booking].present?

            @count = query.count
            order_by = %w[start_at end_at].include?(params[:order_by]) ? params[:order_by] : 'start_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'

            @sessions = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
