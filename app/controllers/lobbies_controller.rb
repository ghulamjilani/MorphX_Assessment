# frozen_string_literal: true

class LobbiesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :fetch_latest_notifications
  before_action :redirect_if_not_rtmp_or_ipcam, only: [:show]
  before_action :load_current_room, except: %i[room_existence stream_alive has_youtube_access]
  before_action :get_ban_reason, only: %i[room_existence show]

  include LobbiesHelper

  def switch_autostart
    session = @room.abstract_session
    if !@room.active? && session.is_a?(Session)
      if session.autostart
        SidekiqSystem::Schedule.remove(ApiJobs::AutoStartSession, @room.id)
        session.update_attribute(:autostart, false)
        render json: { autostart: false }
      else
        # skip for zoom
        ApiJobs::AutoStartSession.perform_at(session.start_at, @room.id) unless @room.zoom?
        session.update_attribute(:autostart, true)
        render json: { autostart: true }
      end
    else
      render json: { autostart: false }
    end
  end

  def switch_chat
    session = @room.abstract_session
    if session.is_a?(Session)
      if session.allow_chat?
        @room.disable_chat
        render json: { allow_chat: false }
      else
        @room.enable_chat
        render json: { allow_chat: true }
      end
    else
      render json: { allow_chat: false }
    end
  end

  def start_fb_stream
    head :ok
  end

  def start_youtube_stream
    head :ok
  end

  # TODO: remove?
  def start_immerss_stream
    head :ok
  end

  def stop_stream
    head :ok
  end

  def stream_alive
    # response = ::Immerss::Api::Immersive.client.stream_pid(params[:id], params[:provider], false)
    # head (response == false ? 404 : response.status)
    head :ok
  end

  def room_existence
    if (room = Room.with_open_lobby.not_cancelled.find_by(id: params[:id]))
      if room.abstract_session.is_a?(Session) && !room.abstract_session.published?
        render json: { message: 'Session is not published or not approved' }, status: 404
      elsif @ban_reason
        render json: { message: I18n.t('video.lobby.banned', reason: @ban_reason) }, status: 404
      else
        render json: {}
      end
    elsif (room = Room.find_by(id: params[:id]))
      abstract_session_type = 'session'
      if room.actual_start_at < Time.now.utc
        render json: { message: I18n.t('video.lobby.non_existence', abstract_session_type: abstract_session_type) },
               status: 404
      else
        render json: { message: I18n.t('video.lobby.not_started', abstract_session_type: abstract_session_type) },
               status: 404
      end
    else
      render json: { message: "Could not find #{abstract_session_type}." }, status: 404
    end
  end

  def has_youtube_access
    head(Identity.where(user_id: current_user.id, provider: 'gplus').where.not(secret: nil).exists? ? :ok : 404)
  end

  def vidyoio
    @lists = @room.session.organization.lists.includes(:products).to_a
    selected_list = @room.abstract_session.lists.first
    if selected_list
      @lists.each { |l| l.selected = (l.id == selected_list.id) }
    end
    gon.channel_name = @room.immersive_channel
    gon.room_id = @room.id
    render layout: 'vidyoio'
  end

  def show
    raise ActiveRecord::RecordNotFound, I18n.t('video.lobby.banned', reason: @ban_reason) if @ban_reason

    @has_youtube_access = Identity.where(user_id: current_user.id, provider: 'gplus').where.not(secret: nil).exists?

    # @room_members = @room.room_members.select([:user_id, :mic_disabled, :video_disabled, :has_control, :backstage]).audience_with_source

    gon.room_id = @room.id
    gon.vidyo_webrtc_domain = ENV['VIDYO_WEBRTC_DOMAIN']
    gon.room_rtmp = @room.rtmp_or_cam?
    gon.current_user_id = current_user.id
    gon.source_id = @source.id if @source
    gon.channel_name = if @role == 'source'
                         @room.source_channel
                       else
                         @room.immersive_channel
                       end

    gon.platform = browser.platform.id
    gon.is_chrome = browser.chrome?
    gon.is_started = @room.active?
    gon.conference_type = @abstract_session.class.to_s
    if @abstract_session.is_a?(Session)
      gon.users_questions_list = Question.where(session_id: @abstract_session.id).order(id: :asc).map(&:user_id)
      gon.dropbox_materials = @abstract_session.dropbox_materials

      gon.can_manage_paypal_donations_visibility = (@abstract_session.organizer == current_user)
    else
      gon.users_questions_list = []
    end

    gon.guest_uri = ENV['VIDEO_GUEST_URL']
    if @role == 'presenter'
      gon.presenter_key = nil
      gon.presenter = true
    else
      gon.guest = true
      gon.has_control = !!@room.room_members.find_by(abstract_user: current_user).try(:has_control)
    end

    gon.plugin_version = 'Unk'

    @lists = @room.session.organization.lists.includes(:products).to_a
    selected_list = @room.abstract_session.lists.first
    if selected_list
      @lists.each { |l| l.selected = (l.id == selected_list.id) }
    end
    gon.lists_enabled = !!@lists.detect(&:selected)

    render layout: 'video'
  end

  # def auth_callback
  #   if @room.rtmp_or_cam? && @role == 'presenter'
  #     head !!::Immerss::Api::Livestream.client.participant_auth(@room.id, current_user.id) ? :ok : 404
  #   else
  #     head !!::Immerss::Api::Immersive.client.participant_auth(@room.id, current_user.id, @role, @source.try(:id)) ? :ok : 404
  #   end
  # end

  # REMOVEME AFTER FIX LOBBIES PAGE
  # def after_join
  #   head !!::Immerss::Api::Immersive.client.after_join(@room.id, current_user.id, @role, @source.try(:id)) ? :ok : 404
  # end

  def start_streaming
    head 404 and return if !@abstract_session.started? || @role != 'presenter'

    @room_control.start

    head :ok
  end

  def stop_streaming
    head 404 and return if @role != 'presenter'

    @room_control.stop

    head :ok
  end

  def be_right_back_on
    head 404 and return if @role != 'presenter'

    @room_control.be_right_back(@room.id)
    head :ok
  end

  def be_right_back_off
    head 404 and return if @role != 'presenter'

    @room_control.be_right_back(false)
    head :ok
  end

  # def start_or_resume_record
  #   head 404 and return if @role != 'presenter'
  #   head !!::Immerss::Api::Immersive.client.start_or_resume_record(@room.id) ? :ok : 404
  # end

  # def pause_record
  #   head 404 and return if !@abstract_session.started? || @role != 'presenter'
  #   head !!::Immerss::Api::Immersive.client.pause_record(@room.id) ? :ok : 404
  # end

  def answer
    head 404 and return unless @role == 'presenter' or @abstract_session.is_a?(Session)

    question = Question.where(session_id: @abstract_session.id, user_id: params[:member_id]).last!

    # head !!::Immerss::Api::Immersive.client.answer(@room.id, question.id, params[:member_id]) ? :ok : 404
    head :ok
  end

  def ask
    head 404 and return unless @role == 'participant'

    # head !!::Immerss::Api::Immersive.client.ask(@room.id, current_user.id) ? :ok : 404
    head :ok
  end

  def silence_all
    head 404 and return unless @role == 'presenter'

    # head !!::Immerss::Api::Immersive.client.silence_all(@room.id) ? :ok : 404
    head :ok
  end

  def allow_control
    head 404 and return unless @role == 'presenter'

    @room_control.allow_control(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def disable_control
    head 404 and return unless @role == 'presenter'

    @room_control.disable_control(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def mute
    head 404 and return unless %w[presenter
                                  source].include?(@role) || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.mute(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def unmute
    head 404 and return unless %w[presenter
                                  source].include?(@role) || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.unmute(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def mute_all
    head 404 and return unless @role == 'presenter'

    @room_control.mute_all
    head :ok
  end

  def unmute_all
    head 404 and return unless @role == 'presenter'

    @room_control.unmute_all
    head :ok
  end

  def start_video
    head 404 and return unless %w[presenter
                                  source].include?(@role) || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.start_video(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def stop_video
    head 404 and return unless %w[presenter
                                  source].include?(@role) || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.stop_video(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def start_all_videos
    head 404 and return unless @role == 'presenter'

    @room_control.start_all_videos
    head :ok
  end

  def stop_all_videos
    head 404 and return unless @role == 'presenter'

    @room_control.stop_all_videos
    head :ok
  end

  def enable_backstage
    head 404 and return unless @role == 'presenter' || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.enable_backstage(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def disable_backstage
    head 404 and return unless @role == 'presenter' || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    @room_control.disable_backstage(params[:room_member_id]) if params[:room_member_id]
    head :ok
  end

  def enable_all_backstage
    head 404 and return unless @role == 'presenter'

    @room_control.enable_all_backstage
    head :ok
  end

  def disable_all_backstage
    head 404 and return unless @role == 'presenter'

    @room_control.disable_all_backstage
    head :ok
  end

  def stop_lecture_mode
    head 404 and return unless @role == 'presenter'

    # head !!::Immerss::Api::Immersive.client.stop_lecture_mode(@room.id) ? :ok : 404
    head :ok
  end

  def start_rtmp_stream # start_ffmpegservice_stream
    if @role == 'presenter' && @room.ffmpegservice_account&.stream_status == 'off'
      @room_control.start_livestream

      flash[:success] = 'Server was restarted'
    else
      flash[:error] = 'Error restart server'
    end
    redirect_back fallback_location: root_path
  end

  def ban_kick
    head 404 and return unless @role == 'presenter' || @room.room_members.find_by(abstract_user: current_user).try(:has_control)

    if (room_member = @room.room_members.find_by(abstract_user_id: params[:banned_id]))
      @room_control.ban_kick(room_member.id, params[:reason_id])
      head :ok
    else
      head 404
    end
  end

  def add_member
    additional_users
    @room_members = @room.room_members.co_presenters_participants
    @member = (@pusers_with_questions + @pusers_without_questions + @co_presenter_users + [@presenter_user]).find do |user|
      user.id == params[:member_id].to_i
    end || raise(ActiveRecord::RecordNotFound)
    respond_to(&:json)
  end

  def refresh_manager_panel
    additional_users
    @room_members = @room.room_members.co_presenters_participants
    respond_to(&:js)
  end

  def dropbox_media_url
    user = @abstract_session.organizer
    if @abstract_session.is_a?(Session) && user.dropbox_token.present?
      material = @abstract_session.dropbox_materials.find(params[:dropbox_material_id])
      responder = proc { render json: { media_url: user.dropbox_repo.get_media(material.path) } }
    else
      responder = proc { render json: {}, status: 422 }
    end
    respond_to do |format|
      format.json(&responder)
    end
  end

  def get_dropbox_media
    if @abstract_session.is_a?(Session)
      user = @abstract_session.organizer
      material = @abstract_session.dropbox_materials.find(params[:dropbox_material_id])
      redirect_to user.dropbox_repo.get_media(material.path)
    else
      head 422
    end
  end

  def change_duration
    head 404 and return if @role != 'presenter'

    @abstract_session.duration = if params[:increase].present?
                                   @abstract_session.duration + 15
                                 else
                                   @abstract_session.duration - 15
                                 end
    if @abstract_session.save
      render json: :ok, status: 200
    else
      render json: { errors: @abstract_session.errors.full_messages.join('.') }, status: 500
    end
  rescue StandardError => e
    render json: { errors: e.message }, status: 500
  end

  def enable_list
    return render(json: { message: 'Access denied.' }, status: 403) unless @role == 'presenter'

    unless @room.abstract_session.is_a?(Session)
      return render(json: { message: 'Lists can be used only for sessions' },
                    status: 404)
    end

    list = @room.enable_list(params[:list_id])
    if list
      render json: { message: "List \"#{list.name}\" enabled." }, status: 200
    else
      render json: { message: 'List doesn\'t exist' }, status: 404
    end
  end

  def disable_list
    return render(json: { message: 'Access denied.' }, status: 403) unless @role == 'presenter'

    unless @room.abstract_session.is_a?(Session)
      return render(json: { message: 'Lists can be used only for sessions' },
                    status: 404)
    end

    @room.disable_list
    render(json: { message: 'Product Lists panel disabled.' }, status: 200)
  end

  private

  def load_current_room
    @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params[:id])
    if @room.abstract_session.is_a?(Session) && !@room.abstract_session.published?
      raise ActiveRecord::RecordNotFound, 'Session is not published or not approved'
    end

    @abstract_session = @room.abstract_session

    @room_control = Control::Room.new(@room)

    @role = if @room.presenter_user_id == current_user.id
              'presenter'
            elsif @abstract_session.is_a?(Session)
              if SessionParticipation.exists?(session_id: @abstract_session.id,
                                              participant_id: current_user.participant_id)
                'participant'
              elsif SessionCoPresentership.exists?(session_id: @abstract_session.id,
                                                   presenter_id: current_user.presenter_id)
                'co_presenter'
              end
            end

    @sources = if @abstract_session.is_a?(Session)
                 @abstract_session.session_sources
               else
                 []
               end

    if @role == 'presenter' && @abstract_session.is_a?(Session) && (@source = @sources.find_by(id: params[:source_id]))
      @role = 'source'
    end
    raise ActiveRecord::RecordNotFound, "Couldn't find Session without an ID" unless @role
  end

  def get_ban_reason
    if (banned_member = RoomMember.find_by(room_id: params[:id], abstract_user: current_user, banned: true))
      @ban_reason = banned_member.ban_reason.name
    end
  end

  def additional_users
    participant_users = @abstract_session.immersive_participants.preload(user: :questions).map do |participant|
      user = participant.user
      user.define_singleton_method(:current_role) { 'participant' }
      if @abstract_session.is_a?(Session)
        user.define_singleton_method(:has_questions?) do |session_id|
          @_has_questions ||= !questions.where(session_id: session_id).length.zero?
        end
      else
        user.define_singleton_method(:has_questions?) { |_session_id| false }
      end
      user
    end

    @pusers_with_questions = participant_users.select do |u|
                               u.has_questions?(@abstract_session.id)
                             end.sort { |u1, u2| u1.questions.last.id <=> u2.questions.last.id }
    @pusers_without_questions = participant_users.reject { |u| u.has_questions?(@abstract_session.id) }

    @co_presenter_users = []
    if @abstract_session.is_a?(Session)
      @co_presenter_users = @abstract_session.co_presenters.preload(:user).map do |co_presenter|
        user = co_presenter.user
        user.define_singleton_method(:current_role) { 'co_presenter' }
        user
      end
    end

    @presenter_user = @abstract_session.organizer
    @presenter_user.define_singleton_method(:current_role) { 'presenter' }

    members = [@presenter_user] + @co_presenter_users + @pusers_with_questions + @pusers_without_questions

    @role = members.find { |user| user.id == current_user.id }.try(:current_role)
  end

  def redirect_if_not_rtmp_or_ipcam
    @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params[:id])
    redirect_to spa_room_path(@room.id) if !@room.rtmp_or_cam? && params[:vidyo].blank?
  end
end
