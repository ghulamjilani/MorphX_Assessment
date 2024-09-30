# frozen_string_literal: true

class SessionsController < Dashboard::ApplicationController
  include ControllerConcerns::ObtainingAccessToSession
  include ControllerConcerns::LatestNotifications
  include ControllerConcerns::SessionFormParams

  skip_before_action :authenticate_user!,
                     only: %i[index preview_share ical participants get_join_button get_stream_url more_from_presenter]
  before_action :additional_gon_init, only: %i[new create edit update clone]
  before_action :get_channel_by_id, only: [:clone]
  before_action :get_channel_by_slug, only: %i[new create pre_time_overlap]
  before_action :load_subscription_limits, only: %i[new edit create pre_time_overlap clone]
  before_action :redirect_if_overlap, only: [:accept_invitation]
  before_action :before_new_record_init, only: %i[new clone]
  before_action :ensure_timecop_travel_is_not_used, only: %i[new edit clone]
  before_action :save_session_settings, only: %i[create update]
  protect_from_forgery except: %i[modal_review preview_live_opt_out_modal preview_accept_invitation preview_clone_modal preview_cancel_modal]

  def index
    if request.xhr?
      sessions = if params[:channel_id].present?
                   Session.for_channel_page_live_guide(date_param: params[:date], channel_id: params[:channel_id],
                                                       used_timezone: used_timezone, current_user: current_user)
                 else
                   Session.for_home_page_live_guide(date_param: params[:date], organizers_param: params[:organizers],
                                                    used_timezone: used_timezone, current_user: current_user)
                 end

      @accumulator = LiveGuideChannelsAggregator.new(sessions).result

      @colors = compound_colors(@accumulator.size)
    else
      redirect_to root_path # no one but Alex can reach this path
    end
  end

  def show
    @session = Channel.find(params[:channel_id]).sessions.find(params[:id])
    redirect_to @session.relative_path
  end

  def new
    if @channel.blank? || cannot?(:create_session, @channel)
      flash[:error] = I18n.t('controllers.sessions.page_not_allowed')
      return redirect_to root_path
    end

    unless can?(:create_session_by_business_plan, @channel.organization)
      flash[:error] = I18n.t('controllers.sessions.business_plan_error')
      return redirect_to root_path
    end

    @session = @channel.sessions.build.tap do |session|
      session.title = session.default_title(current_user)
      session.immersive_type = Session::ImmersiveTypes::GROUP
      session.level = Session.valid_levels.first
      session.duration = 30
      session.start_at = 2.hours.from_now.beginning_of_hour.in_time_zone(current_user.timezone)
      session.autostart = true
      session.allow_chat = true

      # TODO: remove CustomDescriptionFieldLabel
      session.custom_description_field_label = CustomDescriptionFieldLabel.find_by(description: 'Description')&.description || CustomDescriptionFieldLabel.first&.description
      session.min_number_of_immersive_and_livestream_participants = 1
      session.max_number_of_immersive_participants = 5

      session.livestream_purchase_price = 0.0
      session.recorded_purchase_price = 0.0

      session.livestream_free = true
      session.recorded_free = true

      # if current_user.session_setting && current_user.session_setting.service_type != 'zoom'
      #   # TEMPORARY DISABLED MOBILE SESSIONS
      #   # session.device_type = current_user.session_setting.device_type
      #   session.device_type = current_user.session_setting.device_type != 'mobile' ? current_user.session_setting.device_type : 'ipcam'
      #   session.service_type = current_user.session_setting.service_type
      # end
      # For now desktop is disabled
      if session.device_type == 'desktop_basic'
        session.device_type = 'studio_equipment'
        session.service_type = 'rtmp'
      end
      session.start_now = session.device_type != 'mobile'
      session.presenter_id = current_user.presenter_id
    end

    load_backbone_variables
    init_gon_vars
    # load_polls
    # load_poll_categories
    render :new
  end

  def ical
    @session = Channel.find(params[:channel_id]).sessions.find(params[:id])

    authorize!(:read, @session)

    render_ical(@session, @session.channel.description)
  end

  def participants
    @session = Session.find(params[:id])
    authorize!(:read, @session)

    participants = (@session.session_participations.preload(:participant) + @session.livestreamers.preload(:participant)).flatten.uniq.collect do |model|
      user = model.participant.user
      {
        id: user.id,
        is_current_user: user == current_user,
        name: user.public_display_name,
        added: Contact.exists?(for_user: current_user || -1, contact_user_id: user.id),
        picture: user.avatar_url,
        user_url: user.relative_path,
        toggle_url: (toggle_contact_contacts_path(contact_id: user.id) if current_user)
      }
    end

    render json: participants
  end

  def get_access_by_code
    @session = Session.find(params[:id])
    if can?(:purchase_livestream_access, @session)
      @discount = Discount.where(name: params[:code], percent_off_precise: 100, is_valid: true).first
      if @discount&.valid_for?(@session, 'Session', current_user)
        if current_user.present? && current_user.participant.blank?
          current_user.create_participant!
        end
        @participant = current_user.participant
        @session.livestreamers.find_or_create_by!(participant: @participant, free_trial: false)
        flash[:success] = 'You have successfully gained access to the session'
      else
        flash[:error] = 'This code is invalid'
      end
    else
      flash[:error] = "You can't get access to this session"
    end
    redirect_to @session.relative_path
  end

  def clone
    unless can?(:clone_session_by_business_plan, @channel)
      flash[:error] = I18n.t('controllers.sessions.business_plan_error')
      return redirect_back fallback_location: dashboard_path
    end
    @original_session = @channel.sessions.find(params[:id])

    if @original_session.booking.present?
      flash[:error] = I18n.t('controllers.sessions.booked_session_clone_error')
      return redirect_back fallback_location: dashboard_path
    end

    if cannot?(:clone, @original_session)
      flash[:error] = I18n.t('controllers.sessions.page_not_allowed')
      return redirect_to root_path
    end

    interactor = SessionCloning.new(@original_session)

    if params[:session].present?
      if params[:session][SessionsHelper::Clone::INVITES]
        interactor.with_invites!
      end
      if params[:session][SessionsHelper::Clone::DROPBOX_ASSETS]
        interactor.with_dropbox_materials!
      end
    end

    @session = interactor.clone_and_return_session
    @session.start_at = 2.hours.from_now.beginning_of_hour.in_time_zone(current_user.timezone)

    init_gon_vars
    load_backbone_variables
    # load_poll
    # load_poll_categories
    cookies[:immersive] = @session.immersive_delivery_method? ? 1 : 0
    cookies[:livestream] = @session.livestream_delivery_method? ? 1 : 0
    cookies[:record] = @session.recorded_delivery_method? ? 1 : 0

    render :new
  end

  def create
    if @channel.blank?
      flash[:error] = I18n.t('controllers.sessions.action_not_allowed')
      return redirect_back fallback_location: root_path
    end

    unless can?(:create_session_by_business_plan, @channel.organization)
      flash[:error] = I18n.t('controllers.sessions.business_plan_error')
      return redirect_back fallback_location: dashboard_path
    end

    if cannot?(:create_session, @channel)
      flash[:error] = I18n.t('controllers.sessions.action_not_allowed')
      return redirect_to root_path
    end

    Time.use_zone current_user.timezone do
      @session = @channel.sessions.new(session_params)
    end
    if params[:original_session_id] && !params[:session][:cover]
      original_session = Session.find(params[:original_session_id])
      if current_ability.can?(:clone, original_session) && original_session.cover.try(:file)
        @session.crop_x = original_session.crop_x
        @session.crop_y = original_session.crop_y
        @session.crop_h = original_session.crop_h
        @session.crop_w = original_session.crop_w
        @session.rotate = original_session.rotate
        @session.cover = original_session.cover.file
      end
    end
    @session.presenter_id = current_user.presenter_id unless @session.presenter_id

    @session.age_restrictions = 0 if !current_ability.can?(:view_adult_content, current_user) && !current_ability.can?(:view_major_content, current_user)

    @interactor = SessionCreation.new(session: @session,
                                      clicked_button_type: 'published',
                                      ability: current_ability,
                                      invited_users_attributes: invited_users_attributes,
                                      list_ids: params[:list_ids])

    if Session.transaction { @interactor.execute && @session.reload.validate! }
      flash[:success] = I18n.t('controllers.sessions.create_success')

      if @session.start_now
        url = if @session.zoom?
                if can?(:join_as_presenter, @session)
                  @session.zoom_meeting.start_url
                elsif can?(:join_as_participant, session)
                  @session.zoom_meeting.join_url
                end
              else
                spa_room_path(@session.room_id)
              end
        respond_to do |format|
          format.html { redirect_to url }
          format.json { render json: { path: url } }
        end
      else
        respond_to do |format|
          format.html { redirect_to @channel.relative_path }
          format.json { render json: { path: @channel.relative_path } }
        end
      end
    else
      emsg = ['Please, correct the errors listed bellow and re-submit:'] + @session.errors.full_messages

      logger.info @session.errors.full_messages.inspect
      respond_to do |format|
        format.html do
          flash.now[:error] = emsg.join("\n")
          display_interactor_errors(@interactor.session)
          load_backbone_variables
          init_gon_vars

          @session.errors.each do |attr, message|
            # error_immersive_access_cost=
            # error_recorded_access_cost=
            # error_immersive_purchase_price=
            # error_recorded_purchase_price=
            # error_title=
            # error_adult=
            logger.info("error_#{attr}=")
            gon.send("error_#{attr}=", %(<span class="help-inline">#{message}</span>).html_safe)
          end
          render :new
        end
        format.json { render json: emsg.join("\n"), status: 422 }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: e.message, status: 422 }
    end
  end

  def edit
    @session = Session.find_by(slug: params[:id])

    if @session.booking.present?
      flash[:error] = I18n.t('controllers.sessions.booked_session_edit_error')
      return redirect_back fallback_location: dashboard_path
    end

    if cannot?(:edit, @session)
      flash[:error] = I18n.t('controllers.sessions.page_not_allowed')
      return redirect_back fallback_location: root_path
    end

    unless can?(:edit_session_by_business_plan, @session.channel)
      flash[:error] = I18n.t('controllers.sessions.business_plan_error')
      return redirect_back fallback_location: root_path
    end

    @channel = @session.channel

    init_gon_vars
    load_backbone_variables
    render :new
    # load_poll
    # load_poll_categories
  end

  def update
    @session = Session.find_by(slug: params[:id])

    if @session.booking.present?
      flash[:error] = I18n.t('controllers.sessions.booked_session_edit_error')
      return redirect_back fallback_location: dashboard_path
    end

    if cannot?(:edit, @session)
      flash[:error] = I18n.t('controllers.sessions.action_not_allowed')
      return redirect_back fallback_location: root_path
    end

    unless can?(:edit_session_by_business_plan, @session.channel)
      flash[:error] = I18n.t('controllers.sessions.business_plan_error')
      return redirect_back fallback_location: root_path
    end

    Time.use_zone current_user.timezone do
      @session.attributes = session_params.except(:cover)
    end
    @session.cover = session_params[:cover] if session_params[:cover]
    @channel = @session.channel

    @interactor = SessionModification.new(session: @session,
                                          clicked_button_type: 'published',
                                          ability: current_ability,
                                          invited_users_attributes: invited_users_attributes,
                                          list_ids: params[:list_ids])
    if @interactor.execute
      flash[:success] = I18n.t('controllers.sessions.update_success')
      respond_to do |format|
        format.html { redirect_to @channel.relative_path }
        format.json { render json: { path: @channel.relative_path } }
      end
    else
      emsg = ['Please, correct the errors listed bellow and re-submit:'] + @session.errors.full_messages

      logger.debug @session.errors.full_messages.inspect
      respond_to do |format|
        format.html do
          flash.now[:error] = emsg.join("\n")
          display_interactor_errors(@interactor.session)
          init_gon_vars
          load_backbone_variables

          render :new
        end
        format.json { render json: emsg.join("\n"), status: 422 }
      end
    end
  end

  def accept_invitation
    success = true
    message = ''
    redirect_back_location = nil
    redirect_to_location = nil

    @session = Session.find(params[:id])

    if cannot?(:accept_or_reject_invitation, @session)
      success = false
      message = if @session.finished?
                  'The session you are trying to access has ended'
                elsif @session.cancelled?
                  'The session you are trying to access has been cancelled'
                else
                  'Permission denied'
                end
      redirect_back_location = @session.channel.relative_path
    else
      immersive_invited = current_user.participant.present? && @session.session_invited_immersive_participantships.where(participant: current_user.participant).pending.present?
      livestream_invited = current_user.participant.present? && @session.session_invited_livestream_participantships.where(participant: current_user.participant).pending.present?

      co_presenter_invited = current_user.presenter.present? && @session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).pending.present?

      can_accept_invitation_without_paying = lambda do
        # return true if @session.completely_free?

        # NOTE: session may have free and non-free delivery method #1858
        return true if co_presenter_invited
        return true if immersive_invited && @session.immersive_purchase_price.present? && @session.immersive_purchase_price.zero?
        return true if livestream_invited && @session.livestream_purchase_price.present? && @session.livestream_purchase_price.zero?

        false
      end

      ability = AbilityLib::Legacy::AccountingAbility.new(current_user)
      if ability.can?(:accept_co_presenter_invitation_paid_by_organizer, @session)
        accept_invitation_paid_by_organizer

        redirect_to_location = @session.relative_path
      elsif can_accept_invitation_without_paying.call
        if immersive_invited
          @session.session_participations.create!(participant: current_user.participant)

          participantship = @session.session_invited_immersive_participantships.where(participant: current_user.participant).pending.first!
          participantship.accept!
        elsif livestream_invited
          @session.livestreamers.create!(participant: current_user.participant)

          participantship = @session.session_invited_livestream_participantships.where(participant: current_user.participant).pending.first!
          participantship.accept!
        elsif co_presenter_invited
          @session.session_co_presenterships.create!(presenter: current_user.presenter)

          presentership = @session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).pending.first!
          presentership.accept!
        else
          success = false
          message = 'Permission denied'
          redirect_back_location = root_path
        end

        if success
          current_user.touch
          @session.unchain_all!
          message = I18n.t('controllers.mark_invitation_as_accepted_success')
          redirect_to_location = @session.relative_path
        end
      elsif (ability.can?(:purchase_immersive_access, @session) && immersive_invited) || co_presenter_invited
        redirect_to_location = preview_purchase_channel_session_path(@session.slug, type: ObtainTypes::PAID_IMMERSIVE)
      elsif ability.can?(:purchase_livestream_access, @session) && livestream_invited
        redirect_to_location = preview_purchase_channel_session_path(@session.slug, type: ObtainTypes::PAID_LIVESTREAM)
      else
        success = false
        message = 'Permission denied'
        redirect_back_location = root_path
      end
    end

    respond_to do |format|
      format.json { render json: { id: params[:id], success: success, message: message } }
      format.html do
        if message.present?
          if success
            flash[:success] = message
          else
            flash[:error] = message
          end
        end
        if redirect_back_location.present?
          redirect_back fallback_location: redirect_back_location
        elsif redirect_to_location.present?
          redirect_to redirect_to_location
        else
          redirect_back fallback_location: dashboard_path
        end
      end
    end
  end

  def send_email_confirmation_from_preview_purchase
    if current_user.email == params[:email]
      current_user.send_confirmation_instructions
    else
      current_user.email = params[:email]

      if current_user.valid?
        current_user.save!
      else
        flash.now[:error] = current_user.errors.messages.map { |k, v| [k.to_s.humanize, v[0]].join(' ') }.join('. ')
      end
    end

    head :ok
  end

  def preview_clone_modal
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    respond_to do |format|
      format.js { render "sessions/#{__method__}" }
    end
  end

  def toggle_wishlist_item
    if valid_session_request?
      load_session_from_slug
    else
      raise "cant find user, params: #{params.inspect}"
    end

    authorize!(:have_in_wishlist, @session)

    if current_user.has_in_wishlist?(@session)
      current_user.remove_from_wishlist(@session)
      @has_in_wishlist_now = false
    else
      current_user.add_to_wishlist(@session)
      @has_in_wishlist_now = true
    end

    respond_to do |format|
      format.js { render "sessions/#{__method__}" }
    end
  end

  def toggle_remind_me
    @session = Session.find_by(slug: params[:id])
    if current_user.session_reminders.exists?(session: @session)
      current_user.session_reminders.find_by(session: @session).destroy
    else
      current_user.session_reminders.create(session: @session)
      if current_user && @session && @session.immersive_purchase_price.nil? &&
         !@session.livestream_purchase_price.nil? && @session.upcoming?
        interactor = ObtainLivestreamAccessToSession.new(@session, current_user)
        if interactor.can_have_free_trial? || interactor.can_take_for_free?
          obtain_free_livestream_access
          fetch_upcoming_sessions_for_user # for join to stream automatically
        end
      end
    end
    respond_to do |format|
      format.js { head :ok }
    end
  end

  def reject_invitation
    @session = Session.find(params[:id])

    authorize!(:accept_or_reject_invitation, @session)

    if current_user.presenter.present? && @session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).present?
      reject_co_presenter_invitation
    else
      if current_user.participant.present? && @session.session_invited_immersive_participantships.where(participant: current_user.participant).present?
        reject_immersive_participant_invitation
      end
      if current_user.participant.present? && @session.session_invited_livestream_participantships.where(participant: current_user.participant).present?
        reject_livestream_participant_invitation
      end
    end

    current_user.touch

    # in 99% that's just a session to which user was invited and now
    # invitation is rejected
    session.delete(REDIRECT_BACK_TO_AFTER_SIGNUP)

    respond_to do |format|
      format.json { render json: { id: params[:id] } }
      format.html do
        flash[:success] = I18n.t('controllers.sessions.rejected_invitation')
        redirect_back fallback_location: sessions_participates_dashboard_path
      end
    end
  end

  def cancel
    @session = Session.find(params[:id])

    if @session.booking.present?
      flash[:error] = I18n.t('controllers.sessions.booked_session_cancel_error')
      return redirect_back fallback_location: dashboard_path
    end

    authorize!(:cancel, @session)
    reason = AbstractSessionCancelReason.find(params[:session][:abstract_session_cancel_reason_id])

    interactor = SessionCancellation.new(@session, reason)
    if interactor.execute
      flash[:success] = I18n.t('controllers.sessions.cancel_success')
    else
      flash[:error] = I18n.t('controllers.sessions.cancel_error')
    end

    redirect_to @session.channel.relative_path
  end

  def live_opt_out_and_get_money_refund
    @session = Session.find(params[:id])

    authorize!(:live_opt_out_and_get_money_refund, @session)

    interactor = LiveOptOutFromSession.new(@session, current_user)
    interactor.opt_out_and_get_money_refund

    flash[:success] = interactor.success_message or raise 'can not get success message'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  def live_opt_out_without_money_refund
    @session = Session.find(params[:id])

    if !can?(:live_opt_out_and_get_full_system_credit_refund, @session) \
         && !can?(:live_opt_out_with_partial_sys_credit_refund, @session) \
         && !can?(:live_opt_out_without_refund, @session)
      raise 'Permission denied'
    end

    interactor = LiveOptOutFromSession.new(@session, current_user)
    interactor.opt_out_without_money_refund

    flash[:success] = interactor.success_message or raise 'can not get success message'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  def vod_opt_out_without_money_refund
    @session = Session.find(params[:id])

    authorize!(:vod_opt_out, @session)

    interactor = VodOptOutFromSession.new(@session, current_user)
    interactor.opt_out_without_money_refund

    flash[:success] = interactor.success_message or raise 'can not get success message'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  def vod_opt_out_and_get_money_refund
    @session = Session.find(params[:id])

    authorize!(:vod_opt_out_and_get_money_refund, @session)

    interactor = VodOptOutFromSession.new(@session, current_user)
    interactor.opt_out_and_get_money_refund

    flash[:success] = interactor.success_message or raise 'can not get success message'
    redirect_back fallback_location: sessions_participates_dashboard_path
  end

  def toggle_in_waiting_list
    @session = Session.find(params[:id])
    # authorize!(:be_added_to_waiting_list_as_non_free_trial_immersive_method, @session)

    if current_user.in_waiting_list?(@session)
      @session.remove_from_waiting_list(current_user)
      @result = false
    else
      @session.session_waiting_list.users << current_user
      @result = true
    end

    render "sessions/#{__method__}", format: :js
  end

  def request_another_time
    @session = Channel.find(params[:channel_id]).sessions.find(params[:id])

    authorize!(:read, @session)

    @object = RequestAnotherTime.new params.require(:session).permit(:delivery_method, :comment)
    @object.current_user = current_user
    @object.session = @session
    Time.use_zone current_user.timezone do
      @object.requested_at = Time.zone.local(params[:session]['requested_at(1i)'].to_i,
                                             params[:session]['requested_at(2i)'].to_i, params[:session]['requested_at(3i)'].to_i, params[:session]['requested_at(4i)'].to_i, params[:session]['requested_at(5i)'].to_i)
    end

    if @object.valid?
      mailboxer_message = @object.mailboxer_message
      MessageMailer.new_requested_time(mailboxer_message, @session.organizer).deliver_later
      Rails.cache.delete(@session.organizer.unread_messages_count_cache)
      flash.now[:success] = I18n.t('sessions.another_time_request_success')
    else
      Rails.logger.info @object.errors.full_messages
    end

    respond_to(&:js)
  end

  def publish
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_i, params[:id]).last!

    authorize!(:publish, @session)

    @session.status = Session::Statuses::PUBLISHED
    if @session.save(validate: @session.private?) # fixes _access_cost validators
      flash[:success] = I18n.t('controllers.sessions.published_success')
      LiveGuideChannelsAggregator.trigger_live_refresh
    else
      flash[:error] = @session.errors.full_messages.join('.')
    end

    redirect_back fallback_location: root_path
  end

  def modal_review
    @session = Session.find(params[:id])
    @comment = Comment.where(commentable_type: @session.class.to_s, commentable_id: @session.id,
                             user_id: current_user.id).first || Comment.new

    respond_to(&:js)
  end

  def basic_compound_colors
    ['#c88dc4', '#8b8edc', '#5f65d3', '#6c70a7', '#eb98af']
  end

  def compound_colors(number_of_lines)
    if number_of_lines <= SessionsHelper::LIVE_GUIDE_MAX_LINES_WITHOUT_SCROLLING
      basic_compound_colors.take(number_of_lines)
    elsif number_of_lines > SessionsHelper::LIVE_GUIDE_MAX_LINES_WITHOUT_SCROLLING
      result = basic_compound_colors

      more = number_of_lines - SessionsHelper::LIVE_GUIDE_MAX_LINES_WITHOUT_SCROLLING
      repeated_colors = basic_compound_colors + basic_compound_colors + basic_compound_colors + basic_compound_colors
      more.times { |i| result << repeated_colors.at(i) }
      result
    else
      raise ArgumentError
    end
  end

  def preview_accept_invitation
    @session = Session.find(params[:id])

    authorize!(:accept_or_reject_invitation, @session)

    presenter = SessionInvitationButtonsPresenter.new(model_invited_to: @session, current_user: current_user,
                                                      ability: current_ability)
    presenter.prepare_obtain_links

    @body = ''

    if presenter.immersive_links.present?
      @body += <<EOL
        <font style="clear: both; font-weight: normal; line-height: 1.42; color: var(--tp__main); white-space: nowrap; font-size: 14px;">
          As Interactive Delivery Method
        </font>
EOL
               .html_safe
      @body += presenter.immersive_links.join(' ')
    end

    if presenter.immersive_links.present? && presenter.livestream_links.present?
      @body += '<hr style="width: 100% color: var(--border__separator)">'.html_safe
    end

    if presenter.livestream_links.present?
      @body += <<EOL
        <font style=" clear: both; font-weight: normal; line-height: 1.42; color: var(--tp__main); white-space: nowrap; font-size: 14px;">
          As Livestream Delivery Method
        </font>
EOL
               .html_safe
      @body += presenter.livestream_links.join(' ')
    end

    respond_to do |format|
      format.json do
        render json: { id: params[:id], accept_immersive: presenter.immersive_links,
                       accept_livestream: presenter.livestream_links }
      end
      format.js { render "sessions/#{__method__}" }
    end
  end

  def preview_cancel_modal
    @session = Session.find(params[:id])

    authorize!(:cancel, @session)
    interactor = SessionCancellation.new(@session)
    @message = interactor.preview_cancel_modal_message

    respond_to do |format|
      format.js { render "sessions/#{__method__}" }
    end
  end

  def preview_live_opt_out_modal
    @session = Session.find(params[:id])

    authorize!(:live_opt_out, @session)

    @refund_coefficient = BraintreeRefundCoefficient.new(@session)
    @payment_transaction = @session.payment_transactions.live_access.not_archived.success.where(user_id: current_user.id).last
    @system_credit_transaction = SystemCreditEntry.live_access.where(commercial_document: @session,
                                                                     participant_id: current_user.participant_id).last
    @transaction = @payment_transaction || @system_credit_transaction

    respond_to do |format|
      format.js { render "sessions/#{__method__}" }
    end
  end

  def preview_vod_opt_out_modal
    @session = Session.find(params[:id])

    authorize!(:vod_opt_out, @session)

    @refund_coefficient = BraintreeRefundCoefficient.new(@session)
    @payment_transaction = @session.payment_transactions.vod_access.not_archived.success.where(user_id: current_user.id).last
    @system_credit_transaction = SystemCreditEntry.vod_access.where(commercial_document: @session,
                                                                    participant_id: current_user.participant_id).last
    @transaction = @payment_transaction || @system_credit_transaction

    respond_to do |format|
      format.js { render "sessions/#{__method__}" }
    end
  end

  def unchain
    session = Session.find(params[:id])
    authorize!(:edit, session)
    if params[:all].present?
      session.unchain_all!
      flash[:success] = 'All the sessions have been successfully unchained'
    else
      session.unchain!
      flash[:success] = 'The session has been successfully unchained'
    end
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_back fallback_location: root_path
  end

  def pre_time_overlap
    if @channel.blank?
      responder = proc { render json: { message: I18n.t('controllers.sessions.action_not_allowed') }, status: 422 }
    else
      session = if params[:id]
                  @channel.sessions.where('sessions.id = ? OR sessions.slug = ?',
                                          params[:id].to_immerss_i, params[:id]).last!
                else
                  @channel.sessions.build
                end
      if params[:session][:custom_start_at]
        date = DateTime.parse(params[:session][:custom_start_at])
        params[:session]['start_at(4i)'] = date.hour.to_s
        params[:session]['start_at(5i)'] = date.minute.to_s
      end
      session.attributes = params[:session].permit(:start_at, :start_now, :duration, :pre_time, :title, :presenter_id)
      session.start_at = 2.seconds.from_now if session.start_now

      session.send(:not_in_the_past) # fix 1200 :/
      responder = if session.errors[:start_at].present?
                    proc { render json: { message: "Start at #{session.errors[:start_at].join('.')}" }, status: 422 }
                  else
                    proc { render json: session.overlapped_sessions(params.permit(:start_at, :end_at)) }
                  end
    end

    respond_to do |format|
      format.json(&responder)
    end
  end

  def modal_live_participants_portal
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    @users = @session.invited_users_as_json

    respond_to(&:js)
  end

  def modal_live_participants_video
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    authorize!(:edit, @session)

    respond_to(&:js)
  end

  # this action is needed for updating invited users(participants & co-presenters)
  # the modal window is called from non-video pages
  def invited_users_portal
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    @invited_users_attributes = JSON.parse(params[:invited_users_attributes]).collect(&:symbolize_keys)
    @invited_users_attributes.uniq! { |h| h[:email] } # Fix for #2969
    @invited_users_attributes = @invited_users_attributes.map { |h| { email: h[:email], state: h[:state], add_as_contact: h[:add_as_contact] } }
    interactor = SessionInviteUsers.new(session: @session,
                                        current_user: current_user,
                                        invited_users_attributes: @invited_users_attributes)

    unless interactor.execute
      flash.now[:error] = interactor.session.errors.full_messages.join('.')
      flash.now[:error] ||= 'Error during invitation. Please try again.'
    end

    respond_to(&:js)
  end

  def instant_invite_user_from_video
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    raise unless ControllerConcerns::Session::HasInvitedUsers::States::ALL.include?(params[:state])

    authorize!(:edit, @session)

    if (email = params[:email])
      if (user = User.find_by(email: email))
        user.create_participant! if user.participant.blank?
        begin
          if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
            @session.session_invited_immersive_participantships.create(participant: user.participant)
          end

          if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
            @session.session_invited_livestream_participantships.create(participant: user.participant)
          end

          if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
            user.create_presenter! if user.presenter.blank?
            @session.session_invited_immersive_co_presenterships.create(presenter: user.presenter)
          end

          flash.now[:success] = "#{user.public_display_name || user.email} has been invited"
        rescue ActiveRecord::RecordInvalid => e
          flash.now[:error] = e.message
        end
      else
        user = User.invite!({ email: email }, current_user) do |u|
          u.before_create_generic_callbacks_and_skip_validation
          u.skip_invitation = true
        end

        if user.valid?
          user.create_participant! if user.participant.blank?
          begin
            if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
              @session.session_invited_immersive_participantships.create(participant: user.participant)
            end

            if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
              @session.session_invited_livestream_participantships.create(participant: user.participant)
            end

            if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
              user.create_presenter! if user.presenter.blank?
              @session.session_invited_immersive_co_presenterships.create(presenter: user.presenter)
            end

            flash.now[:success] = "#{user.public_display_name || user.email} has been invited"
          rescue ActiveRecord::RecordInvalid => e
            flash.now[:error] = e.message
          end
        else
          flash.now[:error] = 'Invalid email format'
        end
      end
    else
      flash.now[:error] = "Email can't be blank"
    end

    @session.notify_unnotified_invited_participants

    respond_to(&:js)
  end

  def instant_remove_invited_user_from_video
    @session = Session.where('sessions.id = ? OR sessions.slug = ?', params[:id].to_immerss_i, params[:id]).last!

    authorize!(:edit, @session)

    user = User.find_by(email: params[:email])

    x1 = @session.session_invited_immersive_participantships.where(participant: user.participant).last
    x2 = @session.session_invited_livestream_participantships.where(participant: user.participant).last
    x3 = @session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).last

    already_accepted = (x1.present? && x1.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED) || \
                       (x2.present? && x2.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED) || \
                       (x3.present? && x3.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)

    if already_accepted
      flash[:error] = 'This user has already accepted invitation.'
    else
      x1.destroy if x1.present?
      x2.destroy if x2.present?
      x3.destroy if x3.present?
    end

    respond_to(&:js)
  end

  # for shop tab in player from channel/session page
  def get_stream_url
    session = Session.not_cancelled.find(params[:id])
    data = { session_id: params[:id], active: session.room.ffmpegservice_account&.stream_up? }
    if current_user && session &&
       !session.session_participations.exists?(participant_id: current_user.participant_id) &&
       session.livestream_delivery_method? && !session.immersive_delivery_method? && session.upcoming?
      interactor = ObtainLivestreamAccessToSession.new(session, current_user)
      if interactor.can_have_free_trial? || interactor.can_take_for_free? || interactor.has_subscription?
        interactor.free_type_is_chosen!
        interactor.execute
        if interactor.success_message
          data[:livestream_obtained] = true
        end
      end
    end
    wa = if session.room
           session.room.ffmpegservice_account || FfmpegserviceAccount.new
         end
    # Return test stream url if dev
    if session.started? && session.room && session.in_progress? && (can?(:view_livestream_as_guest, session) ||
      (current_user && (can?(:view_free_livestream,
                             session) || can?(:join_as_presenter,
                                              session) || can?(:join_as_livestreamer,
                                                               session) || can?(:access_as_subscriber, session))))
      if Rails.env.development?
        data[:stream_url] = 'https://www.radiantmediaplayer.com/media/bbb-360p.mp4'
        data[:stream_url] =
          ['https://multiplatform-f.akamaihd.net/i/multi/april11/sintel/sintel-hd_,512x288_450_b,640x360_700_b,768x432_1000_b,1024x576_1400_m,.mp4.csmil/master.m3u8'].sample
      elsif wa.stream_up?
        data[:stream_url] = wa.stream_m3u8_url
      end
    end

    render json: data
  end

  def get_join_button
    @session = Session.find(params[:id])
    respond_to(&:json)
  end

  def more_from_presenter
    session = Session.find(params[:session_id])
    @replays = if session
                 Video.with_new_vods.not_fake.where('sessions.presenter_id = ?',
                                                    session.presenter_id).limit(10).order('RANDOM()').preload(:session)
               else
                 []
               end
  end

  def apply_coupon
    session = Session.find(params[:session_id])
    obtain_type = params[:obtain_type]
    coupon = Discount.find_by(name: params[:coupon])
    if coupon && session && coupon.valid_for?(session, obtain_type, current_user)
      render json: {
        coupon: { name: params[:coupon], amount_off: coupon.amount_off_cents,
                  percent_off_precise: coupon.percent_off_precise }, valid: true
      }
    else
      render json: { coupon: {}, valid: false }, status: 422
    end
  end

  private

  def invited_users_attributes
    return [] if params[:session][:invited_users_attributes].blank?

    attrs = params[:session][:invited_users_attributes]
    JSON.parse(attrs).collect(&:symbolize_keys)
  end

  def load_subscription_limits
    return if @organization.blank?

    # TODO: Add current_organization
    if @organization.split_revenue?
      @subscription = :split_revenue_plan
    else
      @subscription = @organization.user.service_subscription
      @feature_parameters = @subscription&.feature_parameters&.sessions_parameters&.preload(:plan_feature) || []
    end
  end

  def load_backbone_variables
    if action_name.to_s == 'clone'
      @users = @original_session.invited_users_as_json.collect { |hash| hash[:status] = 'pending'; hash }
    elsif action_name.to_s == 'edit' && request.get?
      @users = @session.invited_users_as_json
    elsif request.get?
      @users = []
    else
      raw = params[:session][:invited_users_attributes]
      @users = raw ? JSON.parse(raw) : []
    end

    # check allowed channels
    if current_user.current_organization.blank?
      raise AccessForbiddenError
    elsif current_user == current_user.current_organization.user
      @channels = current_user.current_organization.channels.approved.not_archived.order(title: :asc)
    else
      code = case params[:action]
             when 'new'
               :create_session
             when 'edit'
               :edit_session
             when 'clone'
               :clone_session
             end
      @channels = current_user.organization_channels_with_credentials(current_user.current_organization, code).approved.not_archived.order(title: :asc)
    end

    # allow owner create and assign session to any presenter invited to this channel
    @channel ||= @channels.first
    @channel_presenters = {}
    @channels.each do |channel|
      presenters = [channel.organizer.presenter]
      presenters += OrganizationMembership.for_channel_by_credential(channel.id, :start_session).map(&:presenter)
      @channel_presenters[channel.id] = []
      presenters.flatten.compact.uniq.each do |p|
        @channel_presenters[channel.id] << { name: p.user.public_display_name, id: p.id, avatar_url: p.avatar_url }
      end
    end
    @session.presenter_id ||= @channel_presenters[@channel.id].first[:id] # setup presenter if none
    @lists = current_user.current_organization.lists.map { |list| { id: list.id.to_s, name: list.name } }

    # load zoom info
    if Rails.application.credentials.backend[:initialize][:zoom][:enabled]
      @paid_zoom_account = false
      @connected_zoom_account = current_user.zoom_identity
      if @connected_zoom_account.present?
        begin
          sender = Sender::ZoomLib.new(identity: @connected_zoom_account)
          zoom_user = sender.user
          # 1 is base, 2 is paid
          # We need paid one because replay should be stored in
          # zoom cloud storage (available only for paid accounts)
          # so we can download and transcode it
          @paid_zoom_account = zoom_user[:type].to_i > 1 || Rails.env.development?
          @plan_info = {} # sender.plan_info(zoom_user[:account_id])
        rescue StandardError => e
          @paid_zoom_account = false
          @plan_info = {}
        end
      end
      @zoom_connect_url = user_zoom_omniauth_authorize_url(redirect_path_after_social_signup: request.url)
    end
    load_organizations
    load_previous_sessions
  end

  def additional_gon_init
    return unless user_signed_in?

    gon.revenue_split_title = "Based on #{current_user.current_organization_revenue_percent.to_i}/#{100 - current_user.current_organization_revenue_percent.to_i} revenue split"
    gon.can_publish_n_free_sessions_without_admin_approval = current_user.can_publish_n_free_sessions_without_admin_approval

    if current_user.overriden_minimum_live_session_cost.present?
      gon.overriden_minimum_live_session_cost = current_user.overriden_minimum_live_session_cost.to_f
    end

    gon.free_sessions_without_admin_approval_left_count = current_user.free_sessions_without_admin_approval_left_count
    # IMD-276
    gon.free_private_sessions_without_admin_approval_left_count = current_user.free_private_interactive_without_admin_approval_left_count
    gon.can_create_sessions_with_max_duration = current_user.can_create_sessions_with_max_duration
  end

  def load_session_from_slug
    @session = friendly_id_slug.sluggable
  end

  def valid_session_request?
    friendly_id_slug.sluggable_type == 'Session'
  end

  def friendly_id_slug
    @friendly_id_slug ||= FriendlyId::Slug.where(slug: params[:session_slug]).first
  end

  def accept_invitation_paid_by_organizer
    ActiveRecord::Base.transaction do
      @session.session_co_presenterships.create!(presenter: current_user.presenter)

      presentership = @session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).pending.first!
      presentership.accept!

      flash[:success] = I18n.t('controllers.mark_invitation_as_accepted_success')
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
    end
  end

  def reject_immersive_participant_invitation
    participation = @session.session_invited_immersive_participantships.where(participant: current_user.participant).pending.first!
    participation.reject!
  end

  def reject_livestream_participant_invitation
    participation = @session.session_invited_livestream_participantships.where(participant: current_user.participant).pending.first!
    participation.reject!
  end

  def reject_co_presenter_invitation
    presentership = @session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).pending.first!
    presentership.reject!

    @session.organizer_abstract_session_pay_promises.where(co_presenter: current_user.presenter).first.try(:destroy)
  end

  def get_channel_by_id
    @channel = Channel.find(params[:channel_id])
  end

  def get_channel_by_slug
    @organization = current_user.current_organization || current_user.organization || current_user.organization_memberships_active.first&.organization

    return if @organization.blank?

    @channel = if params[:session] && params[:session][:channel_id]
                 Channel.find_by(id: params[:session][:channel_id])
               elsif params[:channel_id]
                 Channel.find_by(slug: params[:channel_id])
               elsif current_user == @organization.user
                 channels = @organization.channels.visible_for_user(current_user).approved.order(is_default: :desc,
                                                                                                 title: :asc)
                 channels.first
               else
                 code = case params[:action]
                        when 'new'
                          :create_session
                        when 'edit'
                          :edit_session
                        when 'clone'
                          :clone_session
                        end
                 current_user.organization_channels_with_credentials(@organization, code).approved.not_archived.order(is_default: :desc, title: :asc).first
               end
  end

  def before_new_record_init
    expect_user_to_be_confirmed

    return redirect_back fallback_location: root_path unless flash.empty?

    if cannot?(:create_session, @channel)
      flash[:error] = I18n.t('controllers.sessions.page_not_allowed')
      return redirect_to root_path
    end

    cookies[:livestream] = 1
    cookies[:immersive] = 0
    cookies[:record] = 1
  end

  def init_gon_vars
    gon.is_dropbox_authenticated = dropbox_authenticated?
    gon.dropbox_auth_url = dropbox_authenticated? ? '' : dropbox_authorize_url
    gon.dropbox_materials = @session.dropbox_materials.collect(&:as_proper_json)
    gon.max_pre_time = Session::MAX_PRE_TIME
    gon.minimum_session_duration = 15 # minutes
    gon.maximum_session_duration = current_user.can_create_sessions_with_max_duration # minutes
    gon.title = I18n.t('controllers.sessions.overlapped_modal_title')
    gon.revenue_split_multiplier = current_user.current_organization_revenue_percent / 100.0

    gon.max_group_immersive_session_access_cost = SystemParameter.max_group_immersive_session_access_cost.to_f
    gon.max_livestream_session_access_cost = SystemParameter.max_livestream_session_access_cost.to_f
    gon.max_recorded_session_access_cost = SystemParameter.max_recorded_session_access_cost.to_f

    gon.free_trial_immersive_participants = @session.session_participations.where(free_trial: true).count
    gon.free_trial_livestream_participants = @session.livestreamers.where(free_trial: true).count
    gon.max_number_of_livestream_free_trial_slots = SystemParameter.max_number_of_livestream_free_trial_slots
    gon.max_number_of_immersive_participants = @session.max_number_of_immersive_participants
    gon.max_number_of_immersive_participants_with_sources = @session.max_number_of_immersive_participants_with_sources
    gon.max_number_of_zoom_participants = @session.max_number_of_zoom_participants
    gon.max_number_of_webrtcservice_participants = @session.max_number_of_webrtcservice_participants

    gon.has_youtube_access = Identity.where(user_id: current_user.id, provider: 'gplus').where.not(secret: nil).exists?
  end

  def redirect_if_overlap
    @session = Session.find(params[:id])
    if (overlap_session = current_user.participate_between(@session.start_at, @session.end_at).first)
      flash[:error] = I18n.t('activerecord.errors.messages.one_role_at_the_same_time',
                             name: overlap_session.title.to_s,
                             link: overlap_session.relative_path,
                             model: I18n.t("activerecord.models.#{overlap_session.class.to_s.downcase}")).html_safe
      redirect_to @session.relative_path
      false
    end
  end

  def load_poll_categories
    @poll_categories = Worldonline::Category.new.categories
    @poll_categories.collect! { |h| [h['name'], h['id']] }
  end

  def load_polls
    return [] unless @session.room

    threads = []
    connection = Worldonline::Poll.new
    @session.room.polls.each do |poll|
      threads << Thread.new do
        connection.get(poll.poll_id, cookies[poll.poll_id])
      end
    end
  end

  def save_session_settings
    if params[:remember_session_settings]
      session_setting = current_user.session_setting || current_user.build_session_setting
      session_setting.attributes = session_settings_params
      session_setting.save
    else
      current_user.session_setting&.destroy
    end
  end

  def session_settings_params
    params.require(:session).permit(:device_type, :service_type)
  end

  def load_organizations
    available_organizations = available_channels.map(&:organization).uniq

    @organizations = {}

    available_organizations.each do |organization|
      organization_studios = {}
      organization_sources = {}
      organization_studio_rooms = {}

      if organization.multiroom_enabled?
        organization.studios.each do |studio|
          studio_rooms = {}
          studio.studio_rooms.each do |studio_room|
            room_info = {
              id: studio_room.id,
              name: studio_room.name,
              studio_id: studio.id,
              data_name: studio_room.name.downcase
            }
            studio_rooms[studio_room.id] = room_info
            organization_studio_rooms[studio_room.id] = room_info
          end

          organization_studios[studio.id] = {
            id: studio.id,
            name: studio.name,
            data_name: studio.name.downcase,
            studio_rooms: studio_rooms
          }
        end

        organization_sources = organization.ffmpegservice_accounts.where(current_service: %i[ipcam rtmp]).map do |wa|
          {
            id: wa.id,
            name: wa.custom_name,
            data_name: wa.custom_name.downcase,
            current_service: wa.current_service,
            server: wa.server,
            port: wa.port,
            username: wa.username,
            password: wa.password,
            source_url: wa.source_url,
            stream_name: wa.stream_name,
            sandbox: wa.sandbox,
            studio_room_id: wa.studio_room_id.to_i
          }
        end
      end
      if organization.ffmpegservice_transcode
        wa_rtmp = organization.wa_rtmp_paid.order('sandbox asc').first
        wa_ipcam = organization.wa_ipcam_paid.order('sandbox asc').first
      else
        wa_rtmp = organization.wa_rtmp_free.order('sandbox asc').first
        wa_ipcam = organization.wa_ipcam_free.order('sandbox asc').first
      end
      @organizations[organization.id] = {
        id: organization.id,
        studios: organization_studios,
        studio_rooms: organization_studio_rooms,
        sources: organization_sources,
        owned: organization.user_id == current_user.id,
        multiroom_enabled: !!organization.multiroom_enabled?,
        is_sessions_templates_enabled: organization.is_sessions_templates_enabled,
        wa_rtmp: wa_rtmp,
        wa_ipcam: wa_ipcam
      }
    end
  end

  def available_channels
    @available_channels ||= current_user.organization_channels_with_credentials(current_user.current_organization, ::AccessManagement::Credential::Codes::CREATE_SESSION).approved.not_archived.to_a
  end

  def load_previous_sessions
    @previous_sessions ||= Session.where(channel_id: available_channels.pluck(:id), recurring_id: nil)
                                  .order(created_at: :desc)
                                  .limit(15).map do |session|
      {
        id: session.id,
        title: session.title,
        start_at: session.start_at,
        duration: session.duration,
        presenter_user: {
          id: session.presenter.user.id,
          public_display_name: session.presenter.user.public_display_name
        },
        channel: {
          id: session.channel_id,
          title: session.channel.title
        }
      }
    end
  end

  def current_ability
    @current_ability ||= ::AbilityLib::SessionAbility.new(current_user).tap do |ability|
      ability.merge(::AbilityLib::UserAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
      ability.merge(::AbilityLib::ChannelAbility.new(current_user))
    end
  end
end
