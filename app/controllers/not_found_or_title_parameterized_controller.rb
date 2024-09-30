# frozen_string_literal: true

class NotFoundOrTitleParameterizedController < ActionController::Base
  protect_from_forgery except: :preview_share

  include ControllerConcerns::SharedControllerHelper
  include ControllerConcerns::GoService
  include ControllerConcerns::LatestNotifications
  include ControllerConcerns::ObtainingAccessToSession
  include ControllerConcerns::RedirectUtils
  include UpcomingSessionsHelper
  include ControllerConcerns::TracksViews
  include ControllerConcerns::ValidatesRecaptcha
  include ControllerConcerns::Api::V1::CookieAuth

  layout 'application'

  before_action :autodisplay_signin, only: :user_or_channel_or_session_or_organization

  def user_or_channel_or_session_or_organization
    gon.user = current_user&.as_json(only: :id, methods: %i[public_display_name avatar_url])
    gon.emoji_img_url = view_context.image_url('emoji/icons.svg')
    gon.is_mobile = browser.device.mobile?
    if valid_personal_space_request?
      load_user

      channel = @user&.current_organization&.channels&.approved&.listed&.not_fake&.not_archived&.order(is_default: :desc)&.first

      return redirect_to spa_channel_path(channel.slug) if channel.present?

      @first_followers = @user.user_followers.includes(:image).limit(50)
      @followers_count = @user.count_user_followers

      @first_followings = @user.following_users.includes(:image).limit(50)
      @followings_count = @user.following_users_count

      # Load all visible channels for user
      @owned_channels = @user.owned_channels.approved.listed.not_fake.not_archived.order(is_default: :desc)
      @invited_channels = @user.invited_channels.approved.listed.not_fake.not_archived.order(is_default: :desc)
      @organization = @user.organization

      social_links = @user&.account&.social_links || []

      @facebook_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::FACEBOOK }
      @twitter_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::TWITTER }
      @gplus_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::GPLUS }
      @linkedin_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::LINKEDIN }
      @youtube_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::YOUTUBE }
      @instagram_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::INSTAGRAM }
      @telegram_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::TELEGRAM }
      @website_url = social_links.detect { |sl| sl.provider == SocialLink::Providers::EXPLICIT }.try(:link_as_url)

      @user.log_daily_activity(:view, owner: current_user) if user_signed_in?

      redirect_to spa_user_path(@user.slug)
      return
    elsif valid_organization_request?
      authorize!(:read, @organization)
      channel = @organization.channels.visible_for_user(current_user).approved.not_archived.order(is_default: :desc).first
      # TODO: find the way to fix /channels/fivespan-oyoba%2Fguitar
      # when doing
      # return redirect_to spa_channels_path(id: friendly_id_slug.slug)
      if channel.present?
        redirect_to spa_channel_path(id: channel.slug)
      elsif @organization.user == current_user
        redirect_to dashboard_path, flash: { info: 'No active channels' }
      else
        redirect_to root_path, flash: { info: 'No active channels' }
      end
      return
    end

    # Alex said whenever "Channel" page is requested that has some live sessions, display live session instead
    # NOTE: this method has to check that this "override" behavior applies only to non-Google/bing/yandex requests
    #       this is needed so that channel page is properly indexed by crawlers
    # NOTE: UPD - we need channel page according to new design
    # if !page_request_by_crawler? && valid_channel_request? && channel_has_live_upcoming_session?
    #   load_session(channel_has_live_upcoming_session){ return }
    #   join_free_livestream
    #   render 'sessions/show', layout: 'application'
    #   return
    # end

    if valid_channel_request?
      return redirect_to "/#{sluggable_slugs.last.slug}", status: 301 unless latest_slug_version_requested?

      # TODO: find the way to fix /channels/fivespan-oyoba%2Fguitar
      # when doing
      # return redirect_to spa_channels_path(id: friendly_id_slug.slug)
      authorize!(:read, friendly_id_slug.sluggable)
      return redirect_to spa_channel_path(id: friendly_id_slug.slug)
    elsif valid_recording_request?
      load_recording(@recording) { return }
      @lists = @channel.organization.lists.includes(:products)
      selected_list = @recording.lists.first
      if selected_list
        @lists.each { |l| l.selected = (l.id == selected_list.id) }
      end
      @can_rate = can?(:rate, @recording)
      @reviews = @channel.reviews_with_rates.limit(6)
      @reviews_count = @channel.reviews_count
      @recording.log_daily_activity(:view, owner: current_user) if user_signed_in?
      render 'recordings/show', layout: 'application'
      return
    elsif valid_session_request?
      return redirect_to "/#{sluggable_slugs.last.slug}", status: 301 unless latest_slug_version_requested?

      load_session(friendly_id_slug.sluggable) { return }

      if @replay
        if !@replay.status_done?
          return redirect_to @session.relative_path, flash: { info: 'This video has not been yet processed' }
        elsif @replay.deleted_at || ((@replay.fake? || !@replay.show_on_profile?) && @replay.user != current_user)
          return redirect_to @session.relative_path, flash: { info: 'This video is no longer available' }
        end

        @can_rate = can?(:rate, @replay)
      else
        @can_rate = can?(:rate, @session)
      end
      # session ended but there's its replay
      if params[:video_id].nil? && params[:recording_id].nil? && @session.finished? && @session.do_record? && @session.records.available.visible.count.positive?
        return redirect_to @session.records.available.visible.first.absolute_path,
                           flash: { info: I18n.t('sessions.completed_and_ready_to_replay_message',
                                                 service_name: Rails.application.credentials.global[:service_name]) }
      end

      @organization = @channel.organization

      @lists = @session.organization.lists.includes(:products)
      selected_list = @session.lists.first
      @lists.each { |l| l.selected = (l.id == selected_list.id) } if selected_list

      @reviews = @session.channel.reviews_with_rates.limit(6)
      @reviews_count = @session.channel.reviews_count

      if @replay
        @replay.log_daily_activity(:view, owner: current_user) if user_signed_in?
        render 'videos/show', layout: 'application'
      else
        @session.log_daily_activity(:view, owner: current_user) if user_signed_in?
        render 'sessions/show', layout: 'application'
      end
      return
    else
      slug = params[:raw_slug].to_s.downcase
      Rails.logger.info "#{slug} could not be found, investigate"
      raise ActionController::RoutingError, "No route matches #{request.path.inspect}"
    end
  end

  def toggle_follow
    if valid_personal_space_request?
      authorize!(:follow, @user)

      @following = current_user.toggle_follow(@user)

      respond_to do |format|
        format.js { render 'users/toggle_follow' }
      end
    elsif valid_channel_request?
      load_channel friendly_id_slug.sluggable

      authorize!(:follow, @channel)

      @following = current_user.toggle_follow(@channel)
      @count = @channel.count_user_followers

      respond_to do |format|
        format.js { render 'channels/toggle_follow' }
      end
    elsif valid_organization_request?
      authorize!(:follow, @organization)

      @following = current_user.toggle_follow(@organization)

      respond_to do |format|
        format.js { render 'organizations/toggle_follow' }
      end
    else
      raise ArgumentError, params[:raw_slug].to_s.downcase
    end
  end

  def toggle_like
    if valid_recording_request?
      if user_signed_in?
        # has yet to vote OR didnt like it
        if current_user.voted_as_when_voted_for(@recording).nil? || current_user.voted_as_when_voted_for(@recording) == false
          current_user.likes @recording
        elsif current_user.voted_as_when_voted_for(@recording) == true # liked it
          current_user.dislikes @recording
        end

        invalidate_likes_cache(@recording)
      end

      respond_to do |format|
        format.js { render(user_signed_in? ? "recordings/#{__method__}" : { nothing: true }) }
      end
    elsif valid_personal_space_request?
      load_user

      if user_signed_in?
        # has yet to vote OR didnt like it
        if current_user.voted_as_when_voted_for(@user).nil? || current_user.voted_as_when_voted_for(@user) == false
          current_user.likes @user
        elsif current_user.voted_as_when_voted_for(@user) == true # liked it
          current_user.dislikes @user
        end

        invalidate_likes_cache(@user)
      end

      respond_to do |format|
        format.js { render(user_signed_in? ? "users/#{__method__}" : { nothing: true }) }
      end
    elsif valid_channel_request?
      load_channel friendly_id_slug.sluggable

      if user_signed_in?
        # has yet to vote OR didnt like it
        if current_user.voted_as_when_voted_for(@channel).nil? || current_user.voted_as_when_voted_for(@channel) == false
          current_user.likes @channel
        elsif current_user.voted_as_when_voted_for(@channel) == true # liked it
          current_user.dislikes @channel
        end

        invalidate_likes_cache(@channel)
      end

      respond_to do |format|
        format.js { render(user_signed_in? ? "channels/#{__method__}" : { nothing: true }) }
      end
    elsif valid_session_request?
      load_session(friendly_id_slug.sluggable) { return }

      if user_signed_in?
        # has yet to vote OR didnt like it
        if current_user.voted_as_when_voted_for(@session).nil? || current_user.voted_as_when_voted_for(@session) == false
          current_user.likes @session
        elsif current_user.voted_as_when_voted_for(@session) == true # liked it
          current_user.dislikes @session
        end

        invalidate_likes_cache(@session)
      end

      respond_to do |format|
        format.js { render(user_signed_in? ? "sessions/#{__method__}" : { nothing: true }) }
      end
    else
      raise "cant find user, params: #{params.inspect}"
    end
  end

  def preview_share
    if valid_personal_space_request?
      load_user

      @user.reload

      respond_to do |format|
        format.js { render "users/#{__method__}" }
      end
    elsif valid_recording_request?
      @recording.reload

      respond_to do |format|
        format.js { render "recordings/#{__method__}" }
      end
    elsif valid_channel_request?
      @channel = friendly_id_slug.sluggable

      @channel.reload

      respond_to do |format|
        format.js { render "channels/#{__method__}" }
      end
    elsif valid_session_request?
      @model = if params[VIDEO_ID_FOR_SHARING].present?
                 Video.find_by!(id: params[VIDEO_ID_FOR_SHARING])
               else
                 shared = friendly_id_slug.sluggable
                 shared.reload
               end

      session[RETURN_TO_AFTER_CONNECTING_ACCOUNT] = @model.absolute_path
      if params[VIDEO_ID_FOR_SHARING].blank? && @model.immersive_delivery_method? && user_signed_in? && (can?(
        :create_session, @model.channel
      ) || can?(:start, @model))
        @interactive_access_tokens = @model.interactive_access_tokens
      end
      respond_to do |format|
        format.js { render "sessions/#{__method__}", format: :js }
      end
    elsif valid_organization_request?
      @organization.reload

      respond_to do |format|
        format.js { render "organizations/#{__method__}", format: :js }
      end
    else
      raise "cant find model, #{params.inspect}"
    end
  end

  private

  # NOTE: if this method is request, then it is FriendlyId::Slug-kind of request, for sure
  # @return [FriendlyId::Slug]
  def sluggable_slugs
    @sluggable_slugs ||= FriendlyId::Slug.where(sluggable: friendly_id_slug.sluggable).order(id: :asc)
  end

  def latest_slug_version_requested?
    return true if sluggable_slugs.size == 1

    sluggable_slugs.last.slug == params[:raw_slug]
  end

  def invalidate_likes_cache(model)
    Rails.cache.delete(model.likes_cache_key)

    case model
    when Session
      Rails.cache.delete(model.channel.likes_cache_key)
    when Channel
      model.sessions.find_each do |s|
        Rails.cache.delete(s.likes_cache_key)
      end
    when User
      model.presenter.channels.each do |channel|
        Rails.cache.delete(channel.likes_cache_key)
        channel.sessions.find_each do |s|
          Rails.cache.delete(s.likes_cache_key)
        end
      end
    when Recording
      # nothing
    else
      raise models.inspect
    end
  end

  # well behaved bots at least typically include a reference URI
  # bear in mind that Twitter don't follow this rule(doesn't matter here)
  def page_request_by_crawler?
    request.env['HTTP_USER_AGENT'].to_s.match(%r{\(.*https?://.*\)})
  end

  def channel_has_live_upcoming_session?
    channel_has_live_upcoming_session.present?
  end

  def channel_has_live_upcoming_session
    # NOTE: that before that method we already checked that this is a valid channel request
    #      and therefore friendly_id_slug is set
    @channel_has_live_upcoming_session ||= friendly_id_slug.sluggable
                                                           .sessions
                                                           .for_user_with_age(current_user)
                                                           .is_public
                                                           .not_archived
                                                           .not_cancelled
                                                           .not_finished
                                                           .published
                                                           .order(start_at: :asc)
                                                           .first
  end

  def friendly_id_slug
    @friendly_id_slug ||= FriendlyId::Slug.where(slug: params[:raw_slug].to_s.downcase).first
  end

  def valid_organization_request?
    @organization = Organization.where(slug: params[:raw_slug].to_s.downcase).last
    @organization.present?
  end

  def valid_recording_request?
    @recording = Recording.find_by(id: params[:recording_id])
    @recording.present?
  end

  def valid_personal_space_request?
    @user = User.where(slug: params[:raw_slug].to_s.downcase, deleted: [false, nil]).last
    return true if @user.present?

    # NOTE: we have about 200 users with FriendlyId::Slug's in production(last one was created on July 2 2015)
    # lets not ignore those old slugs and vanity URLs because some of those users were bookmarked and indexed by Google.
    # with this update it does not fail anymore.
    # Since July 2 user slugs are stored only in users#slug fields(reserved) and if slug change we don't track its history and reference it to that user anymore.
    if friendly_id_slug.present? && friendly_id_slug.sluggable_type == 'User'
      @user = friendly_id_slug.sluggable
      return true if @user.present?
    end
    false
  end

  def valid_channel_request?
    friendly_id_slug.present? && friendly_id_slug.sluggable_type == 'Channel' && !params[:recording_id]
  end

  def valid_session_request?
    friendly_id_slug.present? && friendly_id_slug.sluggable_type == 'Session'
  end

  def load_recording(recording)
    @recording = recording
    @channel = @recording.channel
    if cannot?(:read, @channel)
      redirect_to root_path, flash: { error: I18n.t('cancan.not_allowed.default') }
      yield
    end

    @organization = @channel.organization

    if can?(:track_view, @recording)
      track_view(@recording)
    end

    if !user_signed_in? && !@channel.approved?
      authenticate_user!
      return
    end

    @you_may_also_like_sessions = if @channel.you_may_also_like_is_visible?
                                    Session.you_may_also_like(current_user).includes(:channel, :room)
                                  else
                                    []
                                  end
    @presenter = @channel.presenter
    @organizer = @presenter ? @presenter.user : nil
    @subscription = @channel.subscription

    # NOTE: @current_organization uses in layouts/application/organization_custom_styles partial for customization pages
    @current_organization = @channel&.organization || @channel&.organizer&.organization

    load_additional_gon
  end

  def load_channel(channel)
    if cannot?(:read, channel)
      redirect_to root_path, flash: { error: I18n.t('cancan.not_allowed.default') }
      yield
    end

    @channel = channel
    @user = @channel.organizer
    return authenticate_user! if !user_signed_in? && !@channel.approved?
  end

  def load_session(current_session)
    @session = current_session
    # NOTE: @current_organization uses in layouts/application/organization_custom_styles partial for customization pages
    @current_organization = @session&.channel&.organization || begin
      @session.channel.organizer.organization
    rescue StandardError
      nil
    end
    join_free_livestream

    checker = CanReadSession.new(current_user, @session)
    unless checker.can?
      redirect_to root_path, flash: { error: checker.cannot_because_of_message }
      yield
    end

    @channel = @session.channel # .preload(:images, :links)
    @you_may_also_like_sessions = if @channel.you_may_also_like_is_visible?
                                    Session.you_may_also_like(current_user).includes(:channel, :room)
                                  else
                                    []
                                  end
    if params[:video_id]
      @replay = Video.includes(:session).find_by(id: params[:video_id])
      if can?(:see_full_version_video, @replay.try(:session))
        track_view(@replay)
      end
    elsif params[:recording_id]
      @recording = Recording.find_by(id: params[:recording_id])
    end
    @presenter = @channel.presenter
    @organizer = @presenter ? @presenter.user : nil

    @immersive_interactor = ObtainImmersiveAccessToSession.new(@session, current_user)
    @livestream_interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
    @subscription = @channel.subscription
    load_additional_gon
    gon.request_different_time_default_value = 1.day.from_now.beginning_of_hour.strftime('%d %B %Y')
    room = @session.room
    if can?(:view_livestream_as_guest, @session) && ((room.rtmp_or_cam? && room.active?) || room.recording_started?)
      gon.livestream_as_guest_url = {
        relative_path: @session.relative_path
      }
    end

    begin
      track_view(@session) if @replay.blank? && can?(:track_view, @session) # to avoid infinite loop redirect between sessions
    rescue ArgumentError => e
      Rails.logger.warn e.message

      raise e unless Rails.env.development?
    end
  end

  def load_user
    authorize!(:read, @user)
  end

  # TODO: remove
  def load_organization
    authorize!(:read, @organization)
  end

  def autodisplay_signin
    if !user_signed_in? && params[:utm_source] == 'email-notification'
      session['autodisplay_modal'] = LandingHelper::SIGN_IN_MODAL
    end
  end

  # autosubscribe if only livestream method and session already started
  def join_free_livestream
    # auto-participate if free
    if current_user && !@session.session_participations.find_by(participant_id: current_user.participant_id) \
        && @session.livestream_delivery_method? \
        && ((!@session.immersive_delivery_method? && @session.in_progress? && @session.room&.ffmpegservice_account&.stream_up?) || cookies["livestream_#{@session.id}"].present?)
      interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
      if interactor.can_have_free_trial? || interactor.can_take_for_free? || interactor.has_subscription? \
        || (@session.livestream_purchase_price.present? && @session.livestream_purchase_price.zero? && cookies["livestream_#{@session.id}"].present?)
        interactor.free_type_is_chosen!
        interactor.execute
        cookies.delete("livestream_#{@session.id}")
      end
    end
  end

  def load_additional_gon
    return unless @channel

    gon.is_channel_and_session_page = true
    if current_user
      gon.current_user_name = current_user.public_display_name.truncate(15)
    end
    gon.channel = gon_channel_attributes(@channel)
    gon.organization = gon_organization_attributes(@channel.organization)
    gon.organizer = gon_organizer_attributes(@channel.organizer)

    # if session page
    if @session
      gon.session = gon_session_attributes(@session)

      if @session.finished?
        gon.current_finished_session = gon_session_attributes(@session)
      else
        gon.session_id = @session.id
        # @live_sessions = [@session] + @live_sessions unless @live_sessions.include?(@session)
      end
    end
    gon.replay = gon_replay_attributes(@replay) if @replay
    gon.recording = gon_recording_attributes(@recording) if @recording

    # gon.full_calendar_events = @channel.sessions.where(cancelled_at: nil).published.for_user_with_age(current_user).collect(&:as_icecube_hash)

    if @session&.room
      # session_channel = if current_user && (current_user.purchased_session?(@session.id) || can?(:view_free_livestream, @session) || can?(:join_as_livestreamer, @session)) || can?(:view_livestream_as_guest, @session)
      session_channel = if (current_user && (can?(:view_free_livestream,
                                                  @session) || can?(:join_as_livestreamer,
                                                                    @session))) || can?(:view_livestream_as_guest,
                                                                                        @session)
                          @session.room.livestream_channel
                        else
                          @session.room.public_livestream_channel
                        end
      gon.upcoming_livestream_channel = { channel: session_channel, relative_path: @session.relative_path }
    end
  end
end
