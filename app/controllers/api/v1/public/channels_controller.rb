# frozen_string_literal: true

module Api
  module V1
    module Public
      class ChannelsController < Api::V1::Public::ApplicationController
        before_action :set_channel, only: [:show]

        def index
          @channels = Channel.approved.visible_for_user(current_user)
          @channels = @channels.where(id: params[:id].split(',')) if params[:id].present?
          @channels = @channels.where(show_on_home: params[:show_on_home]) unless params[:show_on_home].nil?
          @channels = @channels.where(organization_id: params[:organization_id].split(',')) if params[:organization_id].present?
          @count = @channels.count
          order_by = if %w[created_at updated_at listed_at
                           show_on_home].include?(params[:order_by])
                       params[:order_by]
                     else
                       'created_at'
                     end
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
          @channels = @channels.order(Arel.sql("#{order_by} #{order}")).preload(:cover, :logo,
                                                                                :subscription).limit(@limit).offset(@offset)
        end

        def show
          render_json(403, 'Access denied') and return unless can?(:read, @channel)

          @channel.log_daily_activity(:view, owner: current_user) if current_user.present?
        end

        private

        def set_channel
          @channel = Channel.preload(:images, :channel_links, :cover, :logo).friendly.find(params[:id])
        end
      end
    end
  end
end
