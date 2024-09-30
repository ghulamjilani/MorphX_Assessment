# frozen_string_literal: true

module Api
  module V1
    module User
      class RoomMembersController < Api::V1::User::ApplicationController
        before_action :set_room

        def index
          query = @room.room_members.where(kind: %w[participant co_presenter presenter]).preload(:abstract_user)
          @count = query.count

          order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @room_members = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end

        def allow_control
          @room_control.allow_control(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def disable_control
          @room_control.disable_control(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def mute
          @room_control.mute(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def unmute
          @room_control.unmute(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def mute_all
          @room_control.mute_all
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def unmute_all
          @room_control.unmute_all
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def start_video
          @room_control.start_video(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def stop_video
          @room_control.stop_video(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def start_all_videos
          @room_control.start_all_videos
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def stop_all_videos
          @room_control.stop_all_videos
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def ban_kick
          @room_control.ban_kick(params[:id], params[:ban_reason_id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def unban
          @room_control.unban(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def enable_backstage
          @room_control.enable_backstage(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def disable_backstage
          @room_control.disable_backstage(params[:id])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def enable_all_backstage
          @room_control.enable_all_backstage
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def disable_all_backstage
          @room_control.disable_all_backstage
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def pin
          @room_control.pin(params[:room_member_ids])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def pin_only
          @room_control.pin_only(params[:room_member_ids])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def unpin
          @room_control.unpin(params[:room_member_ids])
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        def unpin_all
          @room_control.unpin_all
          render_json 200
        rescue StandardError => e
          render_json 500, e.message, e
        end

        private

        def set_room
          @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params[:room_id])
          @room_control = ::Control::Room.new(@room)
          @session = @room.abstract_session
          @channel = @session.channel

          unless @room.abstract_session.published?
            raise ActiveRecord::RecordNotFound, 'Session is not published or not approved'
          end

          return if current_ability.can?(:edit, @session)

          render_json(403, 'You are not allowed to perform this action.')
        end
      end
    end
  end
end
