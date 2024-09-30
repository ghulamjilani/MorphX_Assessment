# frozen_string_literal: true

module Api
  module V1
    module User
      class SessionsController < Api::V1::ApplicationController
        before_action :authorization_only_for_user

        def index
          query = current_user.upcoming_sessions

          query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?
          query = query.where(presenter_id: params[:presenter_id]) if params[:presenter_id].present?
          query = query.joins(:channel).where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?
          query = query.joins(:booking) if params[:booking].present?

          %w[start_at duration].each do |param_name|
            from_name = "#{param_name}_from".to_sym
            to_name = "#{param_name}_to".to_sym
            if params[from_name].present? && params[to_name].present?
              query = query.where(param_name => params[from_name]..params[to_name])
            elsif params[from_name].present?
              query = query.where("#{param_name} >= ?", params[from_name])
            elsif params[to_name].present?
              query = query.where("#{param_name} <= ?", params[to_name])
            end
          end
          if params[:end_at_from].present?
            query = query.where(
              "(stopped_at IS NULL AND (start_at + (INTERVAL '1 minute' * duration)) >= :end_at) OR (stopped_at IS NOT NULL AND stopped_at >= :end_at)", end_at: params[:end_at_from]
            )
          end
          if params[:end_at_to].present?
            query = query.where(
              "(stopped_at IS NULL AND (start_at + (INTERVAL '1 minute' * duration)) <= :end_at) OR (stopped_at IS NOT NULL AND stopped_at <= :end_at)", end_at: params[:end_at_to]
            )
          end

          @count = query.count
          order_by = %w[start_at end_at].include?(params[:order_by]) ? params[:order_by] : 'start_at'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'

          @sessions = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end

        def new
          authorize!(:create_session, channel)

          if Rails.application.credentials.global.dig(:service_subscriptions, :enabled) || !current_user.current_organization.split_revenue_plan
            @service_subscription = current_user.service_subscription
            @feature_parameters = @service_subscription&.feature_parameters&.sessions_parameters&.preload(:plan_feature) || []
          end
          @channels = channels.order(title: :asc)
          @session = channel.sessions.new(create_session_params)
        end

        def show
          @session = Session.find(params[:id])
        end

        # {"authenticity_token"=>"eeCtfkpmkLyaK8eFOlsazdiq66UcQLVDrcDO3WmE60C5x/3mFwv/sbaap4CiqZIsEXR0+T6v1XegKcJhxmxIbQ==",
        # "channel_id"=>"1",
        # "title"=>"Sharon Hansen Live Session",
        # "livestream"=>"true",
        # "livestream_free"=>"true",
        # "immersive_free"=>"false",
        # "immersive_access_cost"=>"4.99",
        # "invited_users_attributes"=>"[]",
        # "description"=>"",
        # "custom_description_field_value"=>"",
        # "record"=>"true",
        # "recorded_free"=>"true",
        # "recorded_access_cost"=>"0",
        # "allow_chat"=>"on",
        # "private"=>"false",
        # "age_restrictions"=>"0",
        # "ffmpegservice_account_id"=>"",
        # "duration"=>"15",
        # "start_now"=>"true",
        # "start_at(1i)"=>"2021",
        # "start_at(2i)"=>"3",
        # "start_at(3i)"=>"5",
        # "custom_start_at"=>"2021-03-05T16:00:00+02:00",
        # "pre_time"=>"0",
        # "recurring_settings"=>{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"},
        # "level"=>"All Levels",
        # "presenter_id"=>"6",
        # "autostart"=>"true",
        # "device_type"=>"desktop_basic", "service_type"=>"webrtcservice", "immersive"=>"false"}, "remember_session_settings"=>"on", "list_ids"=>[""], "channel_id"=>"eadel-quinu/guitar"}
        def create
          authorize!(:create_session, channel)

          @session = channel.sessions.new(create_session_params)
          @session.presenter_id = current_user.presenter_id unless @session.presenter_id
          @session.age_restrictions = 0 if !current_ability.can?(:view_adult_content,
                                                                 current_user) && !current_ability.can?(
                                                                   :view_major_content, current_user
                                                                 )
          @session.adult = false if @session.adult.nil?

          interactor = SessionCreation.new(session: @session,
                                           clicked_button_type: 'published',
                                           ability: current_ability,
                                           invited_users_attributes: invited_users_attributes,
                                           list_ids: params[:list_ids])
          @status = interactor.execute ? 201 : 422
          render :show, status: @status
        rescue StandardError => e
          render_json(500, e.message, e)
        end

        def update
          @session = Session.find(params[:id])
          unless current_ability.can?(:edit, @session)
            render_json(401, I18n.t('dashboard.channel.cannot_create_sessions')) and return
          end

          @session.update(session_params)
          render :show
        end

        def destroy
          @session = Session.find(params[:id])
          authorize!(:cancel, @session)

          reason = AbstractSessionCancelReason.find(params[:cancel_reason_id])

          interactor = SessionCancellation.new(@session, reason)
          raise ArgumentError unless interactor.execute

          render :show
        end

        def nearest_session
          @session = current_user.nearest_abstract_session

          return if @session.blank?

          @session_sources = @session.session_sources
          @room = @session.room

          @start_at = @session.start_at
          @presenter = false
          if current_ability.can?(:join_as_presenter, @session)
            @start_at = (@session.autostart ? (@session.pre_time ? @room.actual_start_at : @session.start_at) : @room.actual_start_at)
            @type = 'immersive'
            @presenter = true
          elsif current_ability.can?(:join_as_participant, @session) ||
                current_ability.can?(:join_as_co_presenter, @session)
            @start_at = @room.room_members.find_by(abstract_user: current_user).try(:backstage?) ? @room.actual_start_at : @session.start_at
            @type = 'immersive'
          elsif current_ability.can?(:join_as_livestreamer, @session)
            @type = 'livestream'
          else
            @type = 'in_progress'
          end
          @show_page_paths = []
          if @session.zoom?
            link_path = @session.relative_path
            if current_ability.can?(:join_as_presenter, @session)
              link_path = @session.zoom_meeting.start_url
            elsif current_ability.can?(:join_as_participant, @session)
              link_path = @session.zoom_meeting.join_url
            end
            @show_page_paths << link_path
          else
            @existence_path = room_existence_lobby_path(@room.id)
            @session_sources.each do |source|
              if @type == 'immersive'
                @show_page_paths << spa_rooms_path(@room.id, source_id: source.id)
              end
            end

            @show_page_paths << if @show_page_paths.empty? && @type == 'immersive'
                                  spa_room_path(@room.id)
                                else
                                  @session.relative_path
                                end
          end
        end

        def confirm_purchase
          @session = Session.friendly.find(params[:id])
          @type = params[:type]
          case @type
          when ObtainTypes::PAID_IMMERSIVE
            interactor = ObtainImmersiveAccessToSession.new(@session, current_user)
            interactor.paid_type_is_chosen!
          when ObtainTypes::FREE_IMMERSIVE
            interactor = ObtainImmersiveAccessToSession.new(@session, current_user)
            interactor.free_type_is_chosen!
          when ObtainTypes::PAID_LIVESTREAM
            interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
            interactor.paid_type_is_chosen!
          when ObtainTypes::FREE_LIVESTREAM
            interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
            interactor.free_type_is_chosen!
          when ObtainTypes::PAID_VOD
            interactor = ObtainRecordedAccessToSession.new(@session, current_user)
          when ObtainTypes::FREE_VOD
            interactor = ObtainRecordedAccessToSession.new(@session, current_user)
            interactor.free_type_is_chosen!
          else
            raise 'Unsupported type'
          end

          interactor.execute(params)
          current_user.touch

          if interactor.success_message
            @session.unchain_all!
            render_json(200, interactor.success_message)
            Rails.logger.info "user has obtained #{@type} access to session #{@session.always_present_title}"
          else
            render_json(403, interactor.error_message.html_safe)
          end
        end

        private

        def current_ability
          AbilityLib::SessionAbility.new(current_user)
                                    .merge(AbilityLib::UserAbility.new(current_user))
                                    .merge(AbilityLib::ChannelAbility.new(current_user))
        end

        def default_session_params
          {
            adult: false,
            age_restrictions: 0,
            allow_chat: true,
            autostart: true,
            channel_id: channel&.id,
            duration: 30,
            immersive_access_cost: 0,
            immersive_free: true,
            immersive: true,
            level: 'All Levels',
            max_number_of_immersive_participants: channel.sessions.new.max_interactive_participants,
            presenter_id: current_user.presenter&.id,
            private: false,
            record: false,
            start_now: true,
            status: Session::Statuses::PUBLISHED,
            title: channel.sessions.build.default_title,
            recording_layout: ::Webrtcservice::Video::Composition::Layouts::GRID
          }
        end

        def create_session_params
          default_session_params.merge(session_params)
        end

        def session_params
          params.permit(
            :adult,
            :age_restrictions,
            :allow_chat,
            :autostart,
            :custom_description_field_label,
            :custom_description_field_value,
            :description,
            :device_type,
            :duration,
            :free_trial_for_first_time_participants,
            :immersive_access_cost,
            :immersive_free_slots,
            :immersive_free_trial,
            :immersive_free,
            :immersive_type,
            :immersive,
            :level,
            :livestream_access_cost,
            :livestream_free_slots,
            :livestream_free_trial,
            :livestream_free,
            :livestream,
            :max_number_of_immersive_participants,
            :min_number_of_immersive_and_livestream_participants,
            :only_ppv,
            :only_subscription,
            :pre_time,
            :presenter_id,
            :private,
            :publish_after_requested_free_session_is_satisfied_by_admin,
            :record,
            :recorded_access_cost,
            :recorded_free,
            :recording_layout,
            :recurring_settings,
            :requested_free_session_reason,
            :service_type,
            :start_at,
            :start_now,
            :title,
            :twitter_feed_title,
            :ffmpegservice_account_id,
            session_sources_attributes: %i[id name _destroy],
            dropbox_materials_attributes: %i[id path _destroy mime_type]
          ).to_h.symbolize_keys.tap do |result|
            # attr_writes
            # make it possible for GET request to pass any other value in params like '0' or 'false' to set it to false and vice versa
            %i[immersive immersive_free livestream livestream_free record recorded_free
               publish_after_requested_free_session_is_satisfied_by_admin].each do |key|
              result[key] = ['false', false, '0', 0, ''].exclude?(result[key]) unless result[key].nil?
            end

            result[:only_subscription] =
              %w[true 1 on].include?(result[:only_subscription]) || result[:only_subscription] == true
            result[:only_ppv] = %w[true 1 on].include?(result[:only_ppv]) || result[:only_ppv] == true

            if result[:record]
              if (result[:recorded_free].nil? && result[:recorded_access_cost].nil?) || result[:recorded_free]
                result[:recorded_free] = true
                result[:recorded_access_cost] = 0
              end
            else
              result[:recorded_free] = nil
              result[:recorded_access_cost] = nil
            end

            result[:service_type] = 'mobile' if result[:service_type] == 'rtmp'

            unless result[:livestream_free] || result[:immersive_free] || result[:recorded_free]
              result[:publish_after_requested_free_session_is_satisfied_by_admin] = nil
            end
          end
        end

        def channel
          @channel ||= params[:channel_id].present? ? channels.find_by(id: params[:channel_id]) : channels.first

          raise(ActiveRecord::RecordNotFound, 'Channel not found') unless @channel

          @channel
        end

        def channels
          raise(AccessForbiddenError) if current_user.current_organization.blank?

          @channels ||= begin
            if current_user == current_user.current_organization.user
              current_user.current_organization.channels
            else
              current_user.organization_channels_with_credentials(current_user.current_organization, :create_session)
            end.approved.not_archived.order(is_default: :desc, title: :asc)
          rescue StandardError => e
            []
          end

          raise(ActiveRecord::RecordNotFound, 'Channels not found') if @channels.blank?

          @channels
        end

        def invited_users_attributes
          return [] if params[:invited_users_attributes].blank?

          attrs = params[:invited_users_attributes]
          JSON.parse(attrs).collect(&:symbolize_keys)
        end
      end
    end
  end
end
