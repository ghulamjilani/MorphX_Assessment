# frozen_string_literal: true

module Api
  module V1
    module User
      class VideosController < Api::V1::User::ApplicationController
        def index
          channel_id = params[:channel_id]

          query = Video.for_channel_and_user(channel_id, current_user.id)

          query = query.where(show_on_home: true) if params[:show_on_home].present?
          query = query.where(room_id: params[:room_id]) if params[:room_id].present?
          query = query.where(rooms: { abstract_session_id: params[:session_id] }) if params[:session_id].present?

          if params[:start_at_from].present? && params[:start_at_to].present?
            query = query.where('sessions.start_at' => params[:start_at_from]..params[:start_at_to])
          elsif params[:start_at_from].present?
            query = query.where('sessions.start_at >= ?', params[:start_at_from])
          elsif params[:start_at_to].present?
            query = query.where('sessions.start_at <= ?', params[:start_at_to])
          end

          if params[:end_at_from].present?
            query = query.where("(sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) >= ?",
                                params[:end_at_from])
          end
          if params[:end_at_to].present?
            query = query.where("(sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) <= ?",
                                params[:end_at_to])
          end

          if params[:duration_from].present? && params[:duration_to].present?
            query = query.where(duration: params[:duration_from]..params[:duration_to])
          elsif params[:duration_from].present?
            query = query.where('duration >= ?', params[:duration_from])
          elsif params[:duration_to].present?
            query = query.where('duration <= ?', params[:duration_to])
          end

          @count = query.count
          order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @videos = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end
      end
    end
  end
end
