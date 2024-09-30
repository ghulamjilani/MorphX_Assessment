# frozen_string_literal: true

module SessionsHelper
  LIVE_GUIDE_MAX_LINES_WITHOUT_SCROLLING = 5

  module Clone
    INVITES = 'invites'
    DROPBOX_ASSETS = 'dropbox_assets'
  end

  def session_buy_and_purchase_options
    begin
      immersive_free_slots_available = livestream_free_slots_available = 0

      free_trial_seats_immersive_available_message = if @session.immersive_delivery_method?
                                                       if @session.immersive_free_slots.nil?
                                                         "#{@session.line_slots_left} of #{@session.max_number_of_immersive_participants} Spots Available"
                                                       else
                                                         immersive_free_slots_available = @session.immersive_free_slots - @session.session_participations.where(free_trial: true).count
                                                         "#{immersive_free_slots_available} of #{@session.immersive_free_slots} Spots Available"
                                                       end
                                                     else
                                                       ''
                                                     end

      free_trial_seats_livestream_available_message = if @session.livestream_delivery_method?
                                                        unless @session.livestream_free_slots.nil?
                                                          livestream_free_slots_available = @session.livestream_free_slots - @session.livestreamers.where(free_trial: true).count
                                                          "#{livestream_free_slots_available} of #{@session.livestream_free_slots} Spots Available"
                                                        end
                                                      else
                                                        ''
                                                      end

      regular_seats_available_message = if @session.immersive_delivery_method?
                                          "#{@session.line_slots_left} of #{@session.max_number_of_immersive_participants} Spots Available"
                                        else
                                          ''
                                        end
    rescue StandardError => e
      free_trial_seats_immersive_available_message = ''
      free_trial_seats_livestream_available_message = ''
      regular_seats_available_message = ''

      notify_airbrake(e,
                      parameters: {
                        immersive_free_slots: @session.immersive_free_slots,
                        livestream_free_slots: @session.livestream_free_slots,
                        line_slots_left: @session.line_slots_left,
                        max_number_of_immersive_participants: @session.max_number_of_immersive_participants
                      })
    end

    {
      session_id: @session.id,
      is_organizer: @session.organizer == current_user,
      purchased: user_signed_in? ? current_user.purchased_session?(@session.id) : false,
      participate: user_signed_in? ? current_user.participate_in?(@session.id) : false,
      view: user_signed_in? ? current_user.view_in?(@session.id) : false,
      immersive_sold_out: @session.immersive_delivery_method? && @session.line_slots_left.zero?,

      opt_out_as_livestream_participant: can?(:opt_out_as_livestream_participant, @session),
      opt_out_as_immersive_participant: can?(:opt_out_as_immersive_participant, @session),

      immersive_free_slots: @session.immersive_free_slots,
      immersive_free_slots_available: immersive_free_slots_available,

      livestream_free_slots: @session.livestream_free_slots,
      livestream_free_slots_available: livestream_free_slots_available,

      free_trial_seats_immersive_available_message: free_trial_seats_immersive_available_message,
      free_trial_seats_livestream_available_message: free_trial_seats_livestream_available_message,

      immersive_can_have_free_trial: @immersive_interactor.can_have_free_trial?,
      immersive_can_take_for_free: @immersive_interactor.can_take_for_free?,
      immersive_could_be_purchased: @immersive_interactor.could_be_purchased?,
      immersive_delivery_method: @session.immersive_delivery_method?,
      immersive_purchase_price: @session.immersive_purchase_price,

      livestream_can_have_free_trial: @livestream_interactor.can_have_free_trial?,
      livestream_can_take_for_free: @livestream_interactor.can_take_for_free?,
      livestream_could_be_purchased: @livestream_interactor.could_be_purchased?,
      livestream_delivery_method: @session.livestream_delivery_method?,
      livestream_purchase_price: @session.livestream_purchase_price,

      preview_purchase_path_without_get_params: preview_purchase_channel_session_path(@session.slug),
      regular_seats_available_message: regular_seats_available_message
    }
  end

  # NOTE: even if session has VOD delivery method,
  # this sections is not always displayed
  # for example, when user has already bought it
  def display_vod_section_in_right_sidebar?
    return false unless @session.recorded_delivery_method?

    interactor3 = ObtainRecordedAccessToSession.new(@session, current_user)

    condition1 = vod_room_is_fully_ready? || @session.organizer
    condition2 = !vod_room_is_fully_ready?
    condition3 = user_signed_in? && interactor3.could_be_obtained_and_not_pending_invitee? && !vod_room_is_fully_ready?

    condition1 || condition2 || condition3
  end

  # NOTE: if requested from sessions#show page, then 1st session has to be @session to highlight it properly
  # @return [Session]
  def get_live_sessions
    return [] if @channel.archived? || !@channel.approved?

    @channel.live_sessions_for(current_user).preload(:channel)
  end

  def session_status(session)
    return 'Cancelled' if session.cancelled?
    return 'Completed' if session.finished?

    case session.status
    when Session::Statuses::UNPUBLISHED
      'Draft'
    when Session::Statuses::PUBLISHED, Session::Statuses::REQUESTED_FREE_SESSION_APPROVED
      'Approved'
    when Session::Statuses::REQUESTED_FREE_SESSION_PENDING
      'Pending Approval'
    when Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
      'Rejected'
    else
      notify_airbrake(RuntimeError.new("can not interpret #{session.status}"),
                      parameters: {
                        session: session.inspect
                      })
      nil
    end
  end

  def session_visibility(session)
    case session.status
    when Session::Statuses::UNPUBLISHED, Session::Statuses::REQUESTED_FREE_SESSION_APPROVED, Session::Statuses::REQUESTED_FREE_SESSION_PENDING, Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
      'Unpublished'
    when Session::Statuses::PUBLISHED
      'Published'
    else
      notify_airbrake(RuntimeError.new("can not interpret #{session.status}"),
                      parameters: {
                        session: session.inspect
                      })
      nil
    end
  end

  def vod_room_is_fully_ready?
    if @session.room.blank?
      unless @session.cancelled?
        notify_airbrake(RuntimeError.new('session does not have room /cc @Max'),
                        parameters: {
                          session: @session.inspect
                        })
      end
      false
    else
      @session.room.vod_is_fully_ready == true
    end
  end

  def age_restrictions_collection
    [
      ["<span class='none'>13+</span>".html_safe, Session::AGE_RESTRICTIONS[:none]],
      ["<span class='adult'>18+</span>".html_safe, Session::AGE_RESTRICTIONS[:adult]],
      ["<span class='major'>21+</span>".html_safe, Session::AGE_RESTRICTIONS[:major]]
    ]
  end

  def wishlist_icon_class
    if user_signed_in? && current_user.has_in_wishlist?(@model)
      'VideoClientIcon-checkmark'
    else
      'VideoClientIcon-plusF'
    end
  end

  def level_session_form_field_input_html_value(session)
    if session.session_participations.blank? && session.livestreamers.blank? && !session.started?
      return { class: 'styled-select',
               style: 'width: 100%' }
    end

    { class: 'disabled styled-select', disabled: 'disabled', readonly: 'readonly', style: 'width: 100%',
      onclick: 'return false' }
  end

  def adult_session_form_field_input_html_value(session)
    # TODO: -check if requested_free_session_satisfied_at check here is needed at all
    return {} if session.session_participations.blank? && session.livestreamers.blank? && !session.started? && session.requested_free_session_satisfied_at.blank?

    { class: 'disabled', onclick: 'return false' }
  end

  def invited_participant_status(participant)
    @results ||= {}

    return @results[participant.id] unless @results[participant.id].nil?

    @results[participant.id] = begin
      # NOTE: yes, it is not optimized but otherwise we need to hack generic link_to_has_many method
      # and the whole approach of how we deal with nested associations. Let's way until we have more
      # requirements(other associations may want to display additional info too)

      model = @session
      # NOTE: keep this logic in sync with #invited_users_as_json - it fixes #1818
      participation = model.send("#{model.class.to_s.downcase}_invited_immersive_participantships").where(participant: participant).first

      if participant.persisted? && participation.present?
        participation.status
      else
        ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
      end
    end
  end

  def invited_co_presenters_status(presenter)
    participation = @session.session_invited_immersive_co_presenterships.where(presenter: presenter).first

    if presenter.persisted? && participation.present?
      participation.status
    else
      ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
    end
  end

  def invited_livestream_status(participant)
    @results ||= {}

    return @results[participant.id] unless @results[participant.id].nil?

    @results[participant.id] = begin
      # NOTE: yes, it is not optimized but otherwise we need to hack generic link_to_has_many method
      # and the whole approach of how we deal with nested associations. Let's way until we have more
      # requirements(other associations may want to display additional info too)

      model = @session
      # NOTE: keep this logic in sync with #invited_users_as_json - it fixes #1818
      participation = model.send("#{model.class.to_s.downcase}_invited_livestream_participantships").where(participant: participant).first

      if participant.persisted? && participation.present?
        participation.status
      else
        ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
      end
    end
  end

  def formatted_session_duration(duration)
    if (duration % 30).zero?
      "#{duration.to_f / 60} hrs"
    else
      "#{duration} mins"
    end
  end

  def wrapper(tag_name = 'div', &blk)
    result = capture_with_haml(&blk)
    if result.present?
      content_tag(tag_name, result)
    end
  end

  def show_sources_button?(session)
    return false if Rails.env.production? || Rails.env.qa?
    return false if session.finished?

    begin
      (current_user.presenter.primary_presenter?(session) && session.session_sources.present?)
    rescue StandardError
      false
    end
  end

  def show_no_upcoming_session_message?(live_sessions)
    live_sessions.select(&:persisted?).blank?
  end

  def role_for_session(session)
    if can?(:join_as_presenter, session)
      'presenter'
    elsif can?(:join_as_participant, session)
      'participant'
    elsif can?(:join_as_livestreamer, session)
      'livestreamer'
    elsif can?(:join_as_co_presenter, session)
      'co_presenter'
    end
  end
end
