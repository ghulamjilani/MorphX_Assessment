# frozen_string_literal: true

class ChannelsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update submit_for_review list edit_creators]
  before_action :ensure_timecop_travel_is_not_used, only: %i[new edit]
  before_action :set_current_organization

  before_action :load_channel_from_params_id, only: %i[
    archive
    edit
    list
    notify_me
    submit_for_review
    unlist
    update
    streams
    replays
    recordings
    reviews
    edit_creators
    save_creators
    sessions_list
    replays_list
    recordings_list
    full_calendar_events
  ]
  before_action :check_business_plan_limits, only: %i[new create]

  def index
    redirect_to channels_home_path
  end

  def new
    authorize!(:create_channel, current_user.current_organization)
    current_user.create_presenter unless current_user.presenter
    # unless current_user.user_info_ready?
    #   return redirect_to wizard_v2_path
    # end
    @channel = current_user.current_organization.channels.build
    @channel.list_automatically_after_approved_by_admin = true
    #
    # set_gon_variables
    # gon.create_path = channels_path
    # gon.channel_title_remote_validations_path = channel_title_remote_validations_path

    # render :form, layout: 'become_presenter_steps'
    render :edit
  end

  def create
    authorize!(:create_channel, current_user.current_organization)

    current_user.create_presenter unless current_user.presenter

    @channel = current_user.current_organization.channels.build

    @channel.attributes = channel_params

    @channel.cover&.valid?
    @channel.images&.map(&:valid?)
    @channel.channel_links.map(&:valid?)

    if @channel.save(context: :channel_controller)
      @channel.auto_approve!
      @channel.list! if current_ability.can?(:list, @channel)

      # exclude current_user
      params[:presenters]&.delete_if { |_, v| v[:id].to_s == current_user.id.to_s }

      presenters = begin
        params[:presenters].values
      rescue StandardError
        []
      end
      interactor = ChannelProcessPresenterships.new(current_user, @channel, presenters)
      if interactor.execute
        flash[:success] = I18n.t('controllers.channels.create_success')
        responder = proc { render json: { path: dashboard_path } }
      else
        errors = interactor.errors
        responder = proc { render json: errors, status: 422 }
      end
    else
      logger.debug @channel.errors.full_messages
      responder = proc { render json: @channel.errors.messages, status: 422 }
    end
    respond_to do |format|
      format.json(&responder)
    end
  end

  def edit
    authorize!(:edit, @channel)
    #
    # set_gon_variables
    #
    # gon.channel = channel_json
    # gon.presenters = presenters_json
    # gon.update_path = channel_path(@channel)
    # gon.channel_title_remote_validations_path = channel_title_remote_validations_path

    # render :form, layout: 'become_presenter_steps'
    render :edit
  end

  def update
    authorize!(:edit, @channel)
    @channel.attributes = channel_params

    @channel.cover&.valid?
    @channel.images.map(&:valid?)
    @channel.channel_links.map(&:valid?)
    gon.user_info_ready = current_user.user_info_ready?
    gon.default_user_logo = User.new.medium_avatar_url

    if params[:channel][:organization_id].present? && params[:channel][:organization_id].to_i != @channel.organization_id
      # TODO: - verify if belongs to presenter member
      @channel.organization_id = params[:channel][:organization_id].to_i
    end

    if @channel.save(context: :channel_controller)

      if params[:list_upon_approval]
        @channel.update_attribute(:list_automatically_after_approved_by_admin, true)
      end

      if params[:channel][:submit_for_review]
        @channel.submit_for_review!
      elsif params[:channel][LIST_CHANNEL_IMMEDIATELY.to_sym] && current_ability.can?(:list, @channel)
        @channel.list!
      end

      @channel.submit_for_review! if @channel.draft?

      flash[:success] = I18n.t('controllers.channels.update_success')
      path_to_redirect = [false, 'false'].include?(params[:dashboard]) ? @channel.relative_path : dashboard_url
      responder = proc { render json: { path: path_to_redirect } }
    else
      responder = proc { render json: @channel.errors.full_messages.join(', '), status: 422 }
    end
    respond_to do |format|
      format.json(&responder)
    end
  end

  def edit_creators
    unless can?(:manage_creators, @channel)
      flash[:error] = 'Not allowed by your Business plan'
      return redirect_back fallback_location: spa_dashboard_business_plan_index_path
    end
    @presenterships_data = @channel.channel_invited_presenterships.includes(presenter: [:user])
    @presenterships_json = @presenterships_data.map do |p|
      { id: p.id, email: p.user.email, user_id: p.user.id, avatar_url: p.user.avatar_url,
        full_name: p.user.public_display_name }
    end
    gon.default_user_logo = User.new.medium_avatar_url
    gon.owner_id = @channel.organizer.id
    render :edit_creators
  end

  def save_creators
    unless can?(:manage_creators, @channel)
      flash[:error] = 'Not allowed by your Business plan'
      return redirect_back fallback_location: spa_dashboard_business_plan_index_path
    end
    # exclude current_user
    params[:presenters]&.delete_if { |_, v| v[:user_id].to_s == current_user.id.to_s }

    presenters = begin
      params[:presenters].values
    rescue StandardError
      []
    end
    interactor = ChannelProcessPresenterships.new(current_user, @channel, presenters)
    success = interactor.execute
    if success
      flash[:success] = 'Members successfully updated!'
      responder = proc { render json: { path: dashboard_path } }
    else
      responder = proc { render json: interactor.errors, status: 422 }
    end
    respond_to do |format|
      format.json(&responder)
    end
  end

  def you_may_also_like_visibility
    @channel = Channel.where('id = ? OR slug = ?', params[:id].to_i, params[:id]).last!

    if @channel.organizer == current_user
      new_value = case params[:value]
                  when Channel::Constants::YouMayAlsoLike::VISIBLE
                    true
                  when Channel::Constants::YouMayAlsoLike::HIDDEN
                    false
                  else
                    raise "can not interpret #{params[:value]}"
                  end

      @channel.you_may_also_like_is_visible = new_value
      @channel.save!
    else
      flash[:error] = 'You have no permissions'
    end
    head :ok
  end

  def request_session
    @channel = Channel.find(params[:id])

    authorize!(:request_session, @channel)

    @object = RequestSession.new params.permit(:delivery_method, :comment)
    @object.current_user = current_user
    @object.channel = @channel
    Time.use_zone current_user.timezone do
      time = Time.parse(params[:requested_at])
      date = Date.parse(params[:date])
      @object.requested_at = Time.zone.local(date.year,
                                             date.month,
                                             date.day,
                                             time.hour,
                                             time.min)
    end

    if @object.valid?
      mailboxer_message = @object.mailboxer_message
      MessageMailer.new_requested_session(mailboxer_message, @channel.organizer).deliver_later
      Rails.cache.delete(@channel.organizer.unread_messages_count_cache)
      flash.now[:success] = I18n.t('sessions.another_time_request_success')
    else
      Rails.logger.info @object.errors.full_messages
    end

    respond_to(&:js)
  end

  def notify_me
    authorize!(:be_notified_about_1st_published_session, @channel)

    UpcomingChannelNotificationMembership.create!(channel: @channel, user: current_user)

    flash[:success] = I18n.t('controllers.channels.added_to_notification_list')

    respond_to(&:js)
  end

  def archive
    authorize!(:archive, @channel)

    @channel.archived_at = Time.now
    @channel.save(validate: false) # so that you don't need to return to this when channel validation logic changes

    flash[:success] = I18n.t('controllers.channels.archived')

    redirect_back fallback_location: root_path, allow_other_host: true
  end

  def submit_for_review
    authorize!(:submit_for_review, @channel)
    @channel.submit_for_review!
    flash[:success] = I18n.t('controllers.channels.submitted_for_review')

    redirect_back fallback_location: root_path
  end

  def list
    authorize!(:list, @channel)
    @channel.list!
    flash[:success] = I18n.t('controllers.channels.just_listed')
    redirect_back fallback_location: root_path
  end

  def unlist
    authorize!(:unlist, @channel)
    @channel.unlist!
    flash[:success] = I18n.t('controllers.channels.just_unlisted')
    redirect_back fallback_location: root_path
  end

  def accept_invitation
    @channel = Channel.find(params[:id])

    authorize!(:accept_or_reject_invitation, @channel)
    accept_presenter_invitation
    respond_to do |format|
      format.json { render json: { id: params[:id] } }
      format.html do
        flash[:success] = I18n.t('controllers.mark_invitation_as_accepted_success')
        redirect_to @channel.relative_path
      end
    end
  end

  def reject_invitation
    @channel = Channel.find(params[:id])

    authorize!(:accept_or_reject_invitation, @channel)
    reject_presenter_invitation

    session.delete(REDIRECT_BACK_TO_AFTER_SIGNUP)

    respond_to do |format|
      format.json { render json: { id: params[:id] } }
      format.html do
        flash[:success] = I18n.t('controllers.sessions.rejected_invitation')
        redirect_back fallback_location: dashboard_path
      end
    end
  end

  def streams
    setup_limit_offset(3)
    @query = params[:query]
    @streams = @channel.live_sessions_for(current_user)
    @streams = @streams.search_by_name(@query).reorder(nil) if @query.present?
    @streams = @streams.order(start_at: :asc).limit(@limit).offset(@offset)

    @streams_count = @channel.live_sessions_for(current_user)
    @streams_count = @streams_count.search_by_name(@query).reorder(nil) if @query.present?
    @streams_count = @streams_count.map(&:id).uniq.count
    @total_pages = (@streams_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def replays
    setup_limit_offset(3)
    @query = params[:query]
    @replays = Video.for_channel_and_user(@channel.id, current_user.try(:id) || -1)
    @replays = @replays.search_by_name(@query).reorder(nil) if @query.present?
    @replays = @replays.order('sessions.start_at DESC').limit(@limit).offset(@offset)

    @replays_count = Video.search_by_name(@query).for_channel_and_user(@channel.id, current_user.try(:id) || -1).count
    @total_pages = (@replays_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def recordings
    setup_limit_offset(3)
    @recordings = @channel.recordings.available.visible.limit(@limit).offset(@offset)
    @recordings_count = @channel.recordings.available.visible.count
    @total_pages = (@recordings_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def reviews
    setup_limit_offset
    @reviews = @channel.reviews_with_rates.limit(@limit).offset(@offset)
    @reviews_count = @channel.reviews_count
    @total_pages = (@reviews_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  # for session page
  def sessions_list
    setup_limit_offset
    @sessions = @channel.live_sessions_for(current_user).limit(@limit).offset(@offset)
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def replays_list
    setup_limit_offset
    @replays = Video.for_channel_and_user(@channel.id,
                                          current_user.try(:id) || -1).order('sessions.start_at DESC').limit(@limit).offset(@offset)
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def recordings_list
    setup_limit_offset
    @recordings = @channel.recordings.available.visible.limit(@limit).offset(@offset)
    respond_to do |format|
      format.js
      format.html { redirect_to @channel.relative_path }
    end
  end

  def full_calendar_events
    start_from = params[:start] || DateTime.now.beginning_of_month
    end_to = params[:end] || DateTime.now.end_of_month
    render json: @channel.sessions.where(cancelled_at: nil, fake: false,
                                         start_at: start_from..end_to).published.for_user_with_age(current_user).collect(&:as_icecube_hash)
  end

  private

  def setup_limit_offset(limit = 6, offset = 6)
    @limit = params[:limit].to_i.positive? ? params[:limit].to_i : limit
    @offset = (params[:offset].to_i >= 0) ? params[:offset].to_i : offset
  end

  def accept_presenter_invitation
    presentership = @channel.channel_invited_presenterships.where(presenter: current_user.presenter).pending.first!
    presentership.accept!
    current_user.touch
    begin
      channel.index
    rescue StandardError
      nil
    end
  end

  def reject_presenter_invitation
    presentership = @channel.channel_invited_presenterships.where(presenter: current_user.presenter).pending.first!
    presentership.reject!
    current_user.touch
  end

  def load_channel_from_params_id
    @channel = Channel.where('id = ? OR slug = ?', params[:id].to_i, params[:id]).last!
  end

  def channel_json
    return {} unless @channel

    json = @channel.as_json.slice('id', 'title', 'description', 'category_id', 'channel_type_id',
                                  'approximate_start_date', 'channel_location', 'status', 'tagline')

    json[:cover] = @channel.cover.gallery_item if @channel.cover
    json[:logo] = @channel.logo.form_data if @channel.logo
    # Materials include cover image at 0 index for carousel so lets exclude it
    json[:gallery] = @channel.materials.reject { |h| h[:is_main] }

    json[:tag_list] = @channel.tag_list.join(',')
    json[:owner_type] = @channel.owner_type
    json
  end

  def presenters_json
    return [] unless @channel

    data = @channel.presenterships_data
    data.each { |hash| hash[:current_user] = hash[:user_id] == current_user.id }

    data
  end

  def channel_categories
    ChannelCategory.all.order(featured: :desc, name: :asc).collect { |c| { name: c.name, value: c.id } }
  end

  def channel_types
    ChannelType.all.order(description: :asc).collect { |c| { name: c.description, value: c.id } }
  end

  def user_json
    json = current_user.as_json.slice('id', 'first_name', 'last_name', 'email', 'gender', 'manually_set_timezone',
                                      'slug')
    if current_user.user_account
      json.merge!(current_user.user_account.as_json.slice('tagline', 'bio', 'available_by_request_for_live_vod',
                                                          'bg_image_url', 'talent_list'))
      json[:cover] = current_user.user_account.bg_image_url
    end
    json[:logo] = current_user.medium_avatar_url
    json[:current_user] = true
    json[:presenter_id] = current_user.presenter_id
    json
  end

  def set_gon_variables
    gon.max_images_size = SystemParameter.channel_images_max_count.to_i
    gon.max_links_size = SystemParameter.channel_links_max_count.to_i
    gon.current_user = user_json
    gon.channel_categories = channel_categories
    gon.channel_types = channel_types
    gon.user_info_ready = current_user.user_info_ready?
    gon.default_user_logo = User.new.medium_avatar_url
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end

  def check_business_plan_limits
    unless can?(:create_channel_by_business_plan, current_user.current_organization)
      flash[:error] = case current_user.service_subscription&.service_status
                      when 'active'
                        I18n.t('controllers.channels.business_plan_max_channels_error')
                      else
                        I18n.t('controllers.channels.business_plan_limits_error')
                      end
      redirect_to dashboard_path
    end
  end
end
