# frozen_string_literal: true

module Api
  module V1
    module Guest
      class RoomsController < Api::V1::Guest::ApplicationController
        before_action :authorization_only_for_guest

        def show
          @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params.require(:id))
          raise AccessForbiddenError unless current_guest.room_members.exists?(room: @room)

          load_room_variables

          @service_token = ::Webrtcservice::Video::Token.access_token(room_member: @current_room_member)
          @current_room_member.reload.save!
        end

        def join_interactive_by_token
          @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find_by(id: interactive_access_token.room.id)
          load_room_variables

          interactive_access_token.destroy if interactive_access_token.individual?

          if @current_room_member.blank?
            unless @session.interactive_slots_available?
              raise(AccessForbiddenError, I18n.t('controllers.api.v1.guest.rooms.errors.join_interactive_by_token.session_is_full'))
            end

            @current_room_member = @room.room_members.create!(abstract_user: current_guest, display_name: current_guest.public_display_name, kind: 'participant')
          end

          @service_token = ::Webrtcservice::Video::Token.access_token(room_member: @current_room_member)

          render :show
        end

        def room_existence
          room_ids = Room.with_open_lobby
                         .not_closed.not_cancelled
                         .joins(:session)
                         .joins("LEFT JOIN room_members ON room_members.room_id = rooms.id AND room_members.abstract_user_type = 'Guest'")
                         .joins('INNER JOIN guests on room_members.abstract_user_id::uuid = guests.id')
                         .where(guests: { id: current_guest.id })
                         .where.not(room_members: { banned: true })
                         .where(sessions: { status: ::Session::Statuses::PUBLISHED })
                         .pluck(:id).uniq

          if room_ids.blank?
            raise ActiveRecord::RecordNotFound
          end

          render_json(200, { room_ids: })
        end

        private

        def interactive_access_token
          return @interactive_access_token if @interactive_access_token.present?

          interactive_access_token = InteractiveAccessToken.find_by(token: params.require(:token))
          if interactive_access_token.blank?
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.guest.rooms.errors.join_interactive_by_token.invalid_access_token'))
          end

          unless interactive_access_token.guests?
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.guest.rooms.errors.join_interactive_by_token.guest_access_forbidden'))
          end

          @interactive_access_token = interactive_access_token
        end

        def load_room_variables
          @session = @room&.abstract_session
          validate_room_and_session!

          @channel = @session.channel
          @interactive_access_tokens = InteractiveAccessToken.none
          @current_room_member = @room.room_members.find_by(abstract_user: current_guest)
          if @current_room_member&.banned?
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.guest.rooms.errors.banned',
                         reason: @current_room_member.ban_reason&.name))
          end

          @role = 'participant'
        end

        def validate_room_and_session!
          if @room.blank? || @room.closed? || !@session.running? || !@session.immersive_delivery_method? || !@session.published?
            raise AccessForbiddenError
          end
        end
      end
    end
  end
end
