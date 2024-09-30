# frozen_string_literal: true

class Api::SessionsController < Api::ApplicationController
  include ActionView::Rendering
  include ControllerConcerns::SessionFormParams

  respond_to :json
  before_action :load_session, only: [:confirm_purchase]
  before_action :sanitize_purchase_type, only: [:confirm_purchase]
  # curl -XGET http://localhost:3000/api_portal/channels/1/sessions/ -H 'X-User-Token: 9f3f5ab404dde17472119127b52aeadb1' -H 'X-User-ID:1'
  def index
    @channel = Channel.find(params[:channel_id])
    @limit = (params[:limit] || 5).to_i
    @offset = (params[:offset] || 0).to_i
    @streams = @channel.live_sessions_for(current_user).limit(@limit).offset(@offset)
    @streams_count = @channel.count_live_sessions_for(current_user)
    @total_pages = (@streams_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
  rescue StandardError => e
    render_json(500, e.message, e)
  end

  def new
    channel = Channel.find(params[:channel_id])

    authorize!(:create_session, channel)

    @session = channel.sessions.build.tap do |session|
      session.title          = session.default_title
      session.immersive_type = Session::ImmersiveTypes::GROUP
      session.level          = Session.valid_levels.first
      session.duration       = 30
      session.description    = channel.description
      session.start_at       = 2.hours.from_now.beginning_of_hour
      session.custom_description_field_label = CustomDescriptionFieldLabel.where(description: 'Description').try(:description) || CustomDescriptionFieldLabel.first.description
      session.min_number_of_immersive_and_livestream_participants = 2
      session.max_number_of_immersive_participants = 5
      session.livestream_purchase_price = 0.0
      session.recorded_purchase_price   = 0.0
      session.livestream_free = true
      session.recorded_free   = true
      session.adult = false
    end
    render :session, status: 200
  rescue StandardError => e
    render_json 500, e.message, e
    notify_airbrake(e)
  end

  def create
    channel = Channel.find(params[:channel_id])

    authorize!(:create_session, channel)

    @session = channel.sessions.new(session_params)
    @session.presenter_id = current_user.presenter_id unless @session.presenter_id
    @session.age_restrictions = 0 if !current_ability.can?(:view_adult_content,
                                                           current_user) && !current_ability.can?(:view_major_content,
                                                                                                  current_user)
    @session.adult = false if @session.adult.nil?

    interactor = SessionCreation.new(session: @session,
                                     clicked_button_type: 'published',
                                     ability: current_ability,
                                     invited_users_attributes: invited_users_attributes,
                                     list_ids: params[:list_ids])
    @status = interactor.execute ? 201 : 422
    render :session, status: @status
  rescue StandardError => e
    render_json 500, e.message, e
    notify_airbrake(e)
  end

  def update
    @session = Session.find(params[:id])

    authorize!(:edit, @session)

    channel = @session.channel

    if channel.archived?
      render_json 401, 'Channel is archived' and return
    elsif !channel.approved?
      render_json 401, 'Channel is not approved' and return
    elsif channel.organizer != current_user
      render_json 401, 'You not organizer' and return
    elsif @session.finished?
      render_json 401, 'The session is finished' and return
    elsif @session.cancelled?
      render_json 401, 'The session is cancelled' and return
    elsif @session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
      render_json 401, 'Free session was rejected by admin' and return
    end

    @session.attributes = session_params
    interactor = SessionModification.new(session: @session,
                                         clicked_button_type: 'published',
                                         ability: current_ability,
                                         invited_users_attributes: invited_users_attributes,
                                         list_ids: params[:list_ids])
    @status = interactor.execute ? 202 : 422
    render :session, status: @status
  rescue StandardError => e
    render_json 500, e.message, e
    notify_airbrake(e)
  end

  def session_params
    params.require(:session).permit(
      :adult,
      :allow_chat,
      :age_restrictions,
      :custom_description_field_label,
      :description,
      :duration,
      :free_trial_for_first_time_participants,
      :immersive,
      :immersive_free,
      :immersive_access_cost,
      :immersive_free_trial,
      :immersive_free_slots,
      :immersive_type,
      :recurring_settings,
      :level,
      :livestream,
      :livestream_free,
      :livestream_access_cost,
      :livestream_free_trial,
      :livestream_free_slots,
      :max_number_of_immersive_participants,
      :min_number_of_immersive_and_livestream_participants,
      :pre_time,
      :presenter_id,
      :private,
      :publish_after_requested_free_session_is_satisfied_by_admin,
      :record,
      :recorded_free,
      :recorded_access_cost,
      :requested_free_session_reason,
      :custom_description_field_value,
      :start_at,
      :start_now,
      :autostart,
      :service_type,
      :device_type,
      :title,
      :twitter_feed_title,
      :ffmpegservice_account_id,
      session_sources_attributes: %i[id name _destroy],
      dropbox_materials_attributes: %i[id path _destroy mime_type]
    ).tap do |result|
      # attr_writes
      # so that in validators you can distinguish these flags set from controller and other updates
      # NOTE: raw value is '1' or nil so !! does the trick
      result['immersive']  = !!result['immersive']
      result['livestream'] = !!result['livestream']
      result['record']     = !!result['record']
      result['service_type'] = 'mobile' if result['service_type'] == 'rtmp'
      result['publish_after_requested_free_session_is_satisfied_by_admin'] =
        (result['publish_after_requested_free_session_is_satisfied_by_admin'] == '1' if result['livestream_free'] || result['immersive_free'] || result['recorded_free'])
    end
  end

  def invited_users_attributes
    return [] if params[:session][:invited_users_attributes].blank?

    attrs = params[:session][:invited_users_attributes]
    JSON.parse(attrs).collect(&:symbolize_keys)
  end

  def confirm_purchase
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
      raise 'unknown type'
    end
    interactor.execute(params)
    current_user.touch
    if interactor.success_message
      @session.unchain_all!
      render_json(200, interactor.success_message)
      Rails.logger.info "user has obtained #{@type} access to session #{@session.always_present_title}"
    else
      render_json(401, interactor.error_message.html_safe)
    end
  rescue StandardError => e
    render_json(500, e.message, e)
  end

  def invited_participants
    @session = Room.where(abstract_session_type: 'Session').find(params[:id]).abstract_session
  end

  def invite_participant
    success_message, error_message = nil

    # session = Session.where("id = ? OR slug = ?", params[:id].to_immerss_i, params[:id]).last!
    session = Room.where(abstract_session_type: 'Session').find(params[:id]).abstract_session

    authorize!(:edit, session)

    channel = session.channel

    error_message = 'Session was finished'       if session.finished?
    error_message = 'Session was cancelled'      if session.cancelled?
    error_message = 'Session was rejected'       if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
    error_message = 'Channel was archived'       if channel.archived?
    error_message = 'Only presenter can do this' if session.presenter_id != current_user.presenter_id && channel.organizer == current_user
    error_message = 'Wrong state'                unless ControllerConcerns::Session::HasInvitedUsers::States::ALL.include?(params[:state])
    render(json: { message: error_message }, status: 422) and return if error_message

    if (email = params[:email])
      if (user = User.find_by(email: email))
        user.create_participant! if user.participant.blank?
        begin
          if params[:state] == ControllerConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
            session.session_invited_immersive_participantships.create(participant: user.participant)
          end

          if params[:state] == ControllerConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
            session.session_invited_livestream_participantships.create(participant: user.participant)
          end

          if params[:state] == ControllerConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
            user.create_presenter! if user.presenter.blank?
            session.session_invited_immersive_co_presenterships.create(presenter: user.presenter)
          end

          success_message = "#{user.public_display_name || user.email} has been invited"
        rescue ActiveRecord::RecordInvalid => e
          error_message = e.message
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
              session.session_invited_immersive_participantships.create(participant: user.participant)
            end

            if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || params[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
              session.session_invited_livestream_participantships.create(participant: user.participant)
            end

            if params[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
              user.create_presenter! if user.presenter.blank?
              session.session_invited_immersive_co_presenterships.create(presenter: user.presenter)
            end

            success_message = "#{user.public_display_name || user.email} has been invited"
          rescue ActiveRecord::RecordInvalid => e
            error_message = e.message
          end
        else
          error_message = 'Invalid email format'
        end
      end
    else
      error_message = 'Email can\'t be blank'
    end

    session.notify_unnotified_invited_participants

    if error_message.present?
      render json: { message: error_message }, status: 422
    elsif success_message.present?
      session.unchain_all!
      render json: { message: success_message }, status: 200
    else
      raise 'Unknow error'
    end
  rescue StandardError => e
    status = (e.class.to_s == 'ActiveRecord::RecordNotFound') ? 404 : 500
    render json: { message: e.message }, status: status
  end

  def remove_participant
    success_message, error_message = nil

    # @session = Session.where("id = ? OR slug = ?", params[:id].to_immerss_i, params[:id]).last!
    session = Room.where(abstract_session_type: 'Session').find(params[:id]).abstract_session

    authorize!(:edit, session)

    channel = session.channel

    error_message = 'Session was finished'       if session.finished?
    error_message = 'Session was cancelled'      if session.cancelled?
    error_message = 'Session was rejected'       if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
    error_message = 'Channel was archived'       if channel.archived?
    error_message = 'Only presenter can do this' if session.presenter_id != current_user.presenter_id && channel.organizer == current_user
    error_message = 'Wrong state'                unless ControllerConcerns::Session::HasInvitedUsers::States::ALL.include?(params[:state])
    render(json: { message: error_message }, status: 422) and return if error_message

    user = User.find_by!(email: params[:email])

    x1 = session.session_invited_immersive_participantships.where(participant: user.participant).last
    x2 = session.session_invited_livestream_participantships.where(participant: user.participant).last
    x3 = session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).last

    already_accepted = (x1.present? && x1.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED) || \
                       (x2.present? && x2.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED) || \
                       (x3.present? && x3.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)

    if already_accepted
      error_message = 'This user has already accepted invitation.'
    else
      if x1 || x2 || x3
        success_message = 'User was removed'
      else
        error_message = 'User not found'
      end
      x1.destroy if x1.present?
      x2.destroy if x2.present?
      x3.destroy if x3.present?
    end

    if error_message.present?
      render json: { message: error_message }, status: 422
    elsif success_message.present?
      render json: { message: success_message }, status: 200
    else
      raise 'Unknow error'
    end
  rescue StandardError => e
    status = (e.class.to_s == 'ActiveRecord::RecordNotFound') ? 404 : 500
    render json: { message: e.message }, status: status
  end

  private

  def load_session
    @session = Session.where('id = ? OR slug = ?', params[:id].to_immerss_i, params[:session_slug]).last!
  end

  def sanitize_purchase_type
    @type = params[:type]
    render_json(404, 'Purchase attempt failed. Please try again.') if @type.blank? || ObtainTypes::ALL.exclude?(@type)
  end
end
