# frozen_string_literal: true

class WidgetsController < ApplicationController
  before_action :load_session_and_video, only: %i[shop playlist additions chat player]
  skip_before_action :gon_init
  skip_before_action :check_if_has_needed_cookie
  skip_before_action :extract_refc_from_url_into_cookie
  skip_before_action :check_if_referral_user
  skip_after_action :prepare_unobtrusive_flash
  skip_before_action :fetch_latest_notifications
  skip_before_action :fetch_upcoming_sessions_for_user
  skip_before_action :store_current_location
  before_action :set_current_organization
  after_action :allow_iframe, except: %i[index]
  before_action :set_visitor_cookie

  def index
    @contacts = current_user ? [current_user] + current_user.contacts.joins(:contact_user).map(&:contact_user) : []
  end

  def live
    gon.organizers = params[:organizers] if params[:organizers].present?
    render :live, layout: false
  end

  def shop
    request.variant = :part if params[:part].present?
    respond_to do |format|
      format.html do |html|
        html.part do
          render partial: 'widgets/product', collection: products_list, locals: { current_session: @session }
        end
        html.any { render :shop, layout: false }
      end
    end
  end

  # Additions includes such things as chat and playlist
  def additions
    set_gon_vars
    gon.user = current_user&.as_json(only: :id, methods: %i[public_display_name avatar_url])
    gon.presenter_id = if params[:class] == 'recording'
                         @video.organizer.id
                       else
                         @session.room.presenter_user_id
                       end
    gon.emoji_img_url = view_context.image_url('emoji/icons.svg')
    gon.is_mobile = browser.device.mobile?
    render :additions, layout: false
  end

  def playlist
    playlist = Playlist.new(user: current_user)
    if @video.is_a?(Recording)
      playlist.add_recording(@video, primary: !params[:live]) if @video.visible?
    elsif @video
      playlist.add_video(@video, primary: !params[:live]) if @video.visible_in_embed?
    elsif @session.upcoming? && params.key?(:live)
      playlist.add_session(@session, primary: true)
    end
    unless params[:single_item]
      Video.for_channel_and_user(@session.channel.id, current_user&.id || -1)
           .order('sessions.start_at DESC')
           .where.not(id: @video&.id).limit(40).each do |video|
        playlist.add_video(video)
      end
      if params.key?(:live)
        @session
          .channel
          .live_public_sessions
          .where.not(id: @session.id)
          .limit(10).each do |session|
          playlist.add_session(session)
        end
      end
    end

    render json: playlist
  end

  def player
    set_gon_vars
    gon.user = current_user&.as_json(only: :id)
    gon.playlist_url = playlist_widget_url(
      class: params[:class],
      id: params[:id],
      live: params[:live],
      single_item: params[:single_item],
      external_playlist: params[:external_playlist],
      format: :json
    )
    @company_settings = @session&.channel&.organization&.company_setting
    render :player, layout: false
  end

  def chat
    gon.user = current_user&.as_json(only: :id, methods: %i[public_display_name avatar_url])
    gon.presenter_id = @session.room.presenter_user_id
    gon.webrtcservice_channel_id = @session.webrtcservice_channel_id
    gon.emoji_img_url = view_context.image_url('emoji/icons.svg')
    gon.is_mobile = browser.device.mobile?
    gon.captcha_key = Recaptcha.configuration.site_key
    render layout: false
  end

  def embedv2
    @url = request.base_url
    @assets_url = ENV['ASSET_HOST']
    @options = params[:options].to_s.split(',')
    @id = params[:id]
    @type = params[:class]
    render :embedv2, layout: false
  end

  private

  def allow_iframe
    case params[:class]
    when 'session'
      session = Session.not_cancelled.find(params[:id])
      organization = session.channel.organization
    when 'video'
      video = Video.find(params[:id])
      organization = video.session.channel.organization
    when 'recording'
      video = Recording.find(params[:id])
      organization = video.channel.organization
    else
      organization = nil
    end
    if organization&.embed_domains.present?
      response.headers['Content-Security-Policy'] = "frame-ancestors 'self' #{organization.embed_domains}"
    end
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end

  def load_session_and_video
    if params[:class] == 'session'
      @session = Session.not_cancelled.find(params[:id])
      @video = @session.primary_record
    elsif params[:class] == 'video'
      @video = Video.find(params[:id])
      @session = @video.session
    elsif params[:class] == 'recording'
      @video = Recording.find(params[:id])
      @session = @video.channel.sessions.build
      params[:single_item] = true
    elsif Rails.env.development?
      @video = Video.first
      @session = @video.session
    else
      raise ActiveRecord::RecordNotFound, "Couldn't find page"
    end
    checker = CanReadSession.new(current_user, @session)
    unless checker.can?
      raise ActiveRecord::RecordNotFound, "Couldn't find page"
    end
  end

  def set_gon_vars
    case params[:class]
    when 'session'
      gon.session = { id: @session&.id }
    when 'video'
      gon.session = { id: @session&.id }
      gon.replay = { id: @video&.id, cropped_start_at: @video&.try(:cropped_start_at)&.utc&.to_fs(:rfc3339) }
    when 'recording'
      gon.recording = { id: @video&.id }
    end

    gon.is_live = params.key?(:live)
    gon.has_external_playlist = params.key?(:external_playlist)
    gon.has_chat = params.key?(:chat)
    gon.embed_channel_suffix = "#{params[:class]}-#{params[:id]}"
    gon.is_single_item = params.key?(:single_item)
    gon.captcha_key = Recaptcha.configuration.site_key
    gon.env = Rails.env
  end

  def products_list
    case params[:class]
    when 'session'
      @session.lists.map(&:products).flatten
    when 'recording', 'video'
      @video.lists.map(&:products).flatten
    end
  end

  def set_visitor_cookie
    cookies.permanent[:visitor_id] ||= {
      value: SecureRandom.uuid,
      secure: true,
      same_site: 'None'
    }
  end
end
