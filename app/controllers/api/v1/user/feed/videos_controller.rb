# frozen_string_literal: true

module Api
  module V1
    module User
      module Feed
        class VideosController < Api::V1::ApplicationController
          before_action :authorization_only_for_user

          def index
            ids = current_user.purchased_vods.pluck(:abstract_session_id)
            query = Video.joins(:room).where(room: { abstract_session_id: ids })

            query = query.joins(:session).where(sessions: { channel_id: params[:channel_id] }) if params[:channel_id].present?
            query = query.joins(:session).where(sessions: { presenter_id: params[:presenter_id] }) if params[:presenter_id].present?
            query = query.joins(:channel).where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?

            @count = query.count
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'

            @videos = query.order(created_at: order).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
