# frozen_string_literal: true

module Api
  module V1
    module User
      class RoomsController < Api::V1::User::ApplicationController
        def show
          load_room_variables
          check_room_access
        end

        def join_interactive_by_token
          @session = interactive_access_token.session
          @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find_by(id: @session.room_id)

          unless @room.present? && !@room.closed? && @session.immersive_delivery_method?
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.rooms.errors.session_unavailable'))
          end

          @channel = @session.channel
          @role = (current_user == @room.presenter_user) ? 'presenter' : 'participant'

          unless current_user == @room.presenter_user
            current_user.create_participant! if current_user.participant.blank?

            unless @session.interactive_slots_available?
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.rooms.errors.join_interactive_by_token.session_is_full'))
            end

            begin
              @session.session_participations.find_or_create_by(participant: current_user.participant)
            rescue StandardError
              nil
            end
          end

          @current_room_member = @room.room_members.reload.find_by(abstract_user: current_user)

          interactive_access_token.destroy if interactive_access_token.individual?

          check_room_access

          interactive_service_token
          interactive_access_tokens

          render :show
        end

        def update
          load_room_variables

          if update_action_params[:action].present?
            room_control = ::Control::Room.new(@room)

            case update_action_params[:action]
            when 'start'
              raise AccessForbiddenError unless @role == 'presenter' || current_ability.can?(:start, @session)

              if @room.active?
                @room.errors.add(:base, I18n.t('controllers.api.v1.user.rooms.errors.update.already_started'))
                raise ActiveRecord::RecordInvalid, @room
              end

              unless @session.started?
                @room.errors.add(:base,
                                 I18n.t('controllers.api.v1.user.rooms.errors.update.too_early_to_start',
                                        start_at: @session.start_at.in_time_zone(current_user.timezone).strftime('%b %d %Y, %I:%M %p %Z')))
                raise ActiveRecord::RecordInvalid, @room
              end

              room_control.start
            when 'stop'
              raise AccessForbiddenError unless @role == 'presenter' || current_ability.can?(:end, @session)

              room_control.stop
              @session.update({ stop_reason: 'stopped_by_presenter' })
            when 'start_record', 'stop_record', 'pause_record', 'resume_record'
              unless @role == 'presenter' ||
                     current_ability.can?(:start, @session) ||
                     current_ability.can?(:end, @session)
                raise AccessForbiddenError
              end

              room_control.send(update_action_params[:action])
            end

            @room.reload
            @session.reload

            render(:show) and return
          end

          raise AccessForbiddenError unless @role == 'presenter' || current_ability.can?(:edit, @session)

          @room.update(update_params)
          @session.reload

          render :show
        end

        def room_existence
          if (room = Room.with_open_lobby.not_cancelled.find_by(id: params[:id]))
            current_room_member = room.room_members.find_by(abstract_user: current_user)
            if current_room_member&.banned?
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.rooms.errors.banned',
                           reason: current_room_member.ban_reason&.name))
            end

            if !room.abstract_session.published?
              raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.rooms.errors.session_unavailable'))
            else
              render_json 200
            end
          elsif (room = Room.find_by(id: params[:id]))
            if room.actual_start_at < Time.now.utc
              render_json(404, I18n.t('video.lobby.non_existence', abstract_session_type: 'session'))
            else
              render_json(404, I18n.t('video.lobby.not_started', abstract_session_type: 'session'))
            end
          else
            render_json(404, 'Could not find session.')
          end
        end

        private

        def load_room_variables
          @room = if action_name == 'update' && update_action_params[:action] == 'stop'
                    Room.includes(:abstract_session).not_closed.not_cancelled.find(params[:id])
                  else
                    Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params[:id])
                  end
          @current_room_member = @room.room_members.find_by!(abstract_user: current_user_or_guest)
          @role = @room.role_for(user: current_user)
          @session = @room.abstract_session
          @channel = @session.channel

          if @role == ('presenter') && @room.ffmpegservice?
            @ffmpegservice_account = @room.ffmpegservice_account
          end

          if @session.immersive_delivery_method?
            interactive_service_token
            interactive_access_tokens
          end

          viewer = @session.livestreamers.exists?(participant_id: current_user.participant.try(:id))
          paid_viewer = @session.channel.subscription && StripeDb::Subscription.joins(:stripe_plan).exists?(
            status: :active, user: current_user, stripe_plan: @session.channel.subscription.plans
          )
          free_viewer = @session.channel.free_subscriptions.in_action.with_features(:livestreams).exists?(user: current_user)
          @can_see_livestream = viewer || paid_viewer || free_viewer
        end

        def check_room_access
          raise AccessForbiddenError unless @role

          return if @role == 'presenter'

          unless @session.published? && @session.running?
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.rooms.errors.session_unavailable'))
          end

          if @current_room_member&.banned?
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.rooms.errors.banned',
                         reason: @current_room_member.ban_reason&.name))
          end
        end

        def ban_reason
          room = Room.find(params[:id])
          banned_member = room.room_members.find_by(abstract_user: current_user, banned: true)
          return unless banned_member

          @ban_reason = banned_member.ban_reason.name
        end

        def update_params
          params.require(:room).permit(
            :is_screen_share_available,
            :recording,
            :mic_disabled,
            :video_disabled,
            :backstage,
            room_members_attributes: %i[
              id
              mic_disabled
              video_disabled
              backstage
              pinned
              banned
              ban_reason_id
            ],
            session_attributes: %i[
              id
              allow_chat
            ]
          )
        end

        def update_action_params
          params.require(:room).permit(:action)
        end

        def interactive_access_token
          return @interactive_access_token if @interactive_access_token.present?

          interactive_access_token = InteractiveAccessToken.find_by(token: params.require(:token))
          if interactive_access_token.blank?
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.guest.rooms.errors.join_interactive_by_token.invalid_access_token'))
          end

          @interactive_access_token = interactive_access_token
        end

        def interactive_access_tokens
          @interactive_access_tokens ||= if @session.organization.user == current_user ||
                                            @role == 'presenter' ||
                                            can?(:create_session, @session.channel) ||
                                            can?(:start, @session)
                                           @session.interactive_access_tokens
                                         else
                                           InteractiveAccessToken.none
                                         end
        end

        def interactive_service_token
          return nil unless @current_room_member.present? && current_ability.can?(:join_immersive, @session)

          @service_token ||= ::Webrtcservice::Video::Token.access_token(room_member: @current_room_member)
        end

        def current_ability
          @current_ability ||= AbilityLib::SessionAbility.new(current_user).merge(AbilityLib::ChannelAbility.new(current_user))
        end
      end
    end
  end
end
