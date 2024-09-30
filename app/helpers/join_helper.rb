# frozen_string_literal: true

module JoinHelper
  MAX_TRIES = 4

  def nearest_abstract_session
    @nearest_abstract_session ||= begin
      exception_callback = proc do |_exception|
        current_user.invalidate_nearest_abstract_session_cache
      end

      Retryable.retryable(tries: MAX_TRIES, on: StaleNearestAbstractSessionCache,
                          exception_cb: exception_callback) do |retries, _exception|
        _abstract_session = current_user.nearest_abstract_session

        present_and_stale = (_abstract_session.present? && _abstract_session.finished?) || \
                            (_abstract_session.present? && _abstract_session.room.blank?) || \
                            (_abstract_session.present? && _abstract_session.room.present? && (_abstract_session.room.status == Room::Statuses::CANCELLED || _abstract_session.room.status == Room::Statuses::CLOSED))

        if present_and_stale
          if retries + 1 == MAX_TRIES
            nil
          else
            raise StaleNearestAbstractSessionCache
          end
        else
          _abstract_session
        end
      end
    end
  end

  # @param abstract_session - e.g. Session instance
  # @param link_css_classes - e.g. "session-head-btn mainButton btn" or "btn-grey-solid" String
  #
  # @return object that responds to #html_link and #onclick_value
  def join_room(abstract_session:, link_css_classes: '', initialization_type: nil, enforce_title: false, source_id: nil)
    if abstract_session.cancelled? || abstract_session.finished?
      return OpenStruct.new(html_link: '', onclick_value: '')
    end

    if link_css_classes.include?('join-timer')
      raise 'no need in setting join-timer class explicitely'
    end

    link_css_classes = "join-timer #{link_css_classes}"

    room = abstract_session.room

    raise "clean cache? user_id: #{current_user.id} ; abstract_session: #{abstract_session.inspect}" if room.blank?

    title = if enforce_title
              abstract_session.always_present_title
            else
              ''
            end

    # NOTE: start_at for organizers has to be like: abstract_session.start_at.to_i
    #      for all other roles it has to be room.actual_start_at.to_i
    #      (because of pre-time)
    if abstract_session.is_a?(Session)
      session = abstract_session

      if session.status == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
        return OpenStruct.new(html_link: '', onclick_value: '')
      end

      if can?(:join_as_presenter, session)
        start_at = (session.autostart ? (session.pre_time ? room.actual_start_at : session.start_at) : room.actual_start_at).to_i
        type = 'immersive'
        presenter = true
      elsif can?(:join_as_participant, session) || can?(:join_as_co_presenter, session)
        start_at = session.room_members.find_by(abstract_user: current_user).try(:backstage?) ? room.actual_start_at.to_i : session.start_at.to_i
        type = 'immersive'
        presenter = false
      elsif can? :join_as_livestreamer, session
        start_at = session.start_at.to_i
        type = 'livestream'
        presenter = false
      else
        start_at = session.start_at.to_i
        type = 'in_progress'
        presenter = false
      end
    else
      raise
    end
    html_link = if session.service_type == 'zoom'
                  link_path = session.relative_path
                  if can?(:join_as_presenter, session)
                    link_path = session.zoom_meeting.start_url
                  elsif can?(:join_as_participant, session)
                    link_path = session.zoom_meeting.join_url
                  end
                  link_to('Join',
                          link_path,
                          data: { initialization_type: initialization_type, roomid: room.id, now: Time.now.to_i,
                                  start_at: start_at },
                          style: 'display: none',
                          title: title,
                          class: link_css_classes,
                          target: '_blank')
                elsif (browser.platform.ios? || browser.platform.android?) && temporary_except_livestream?(type)
                  # link_to('Join',  # TODO: immerss?
                  #         "immerss://join?room_id=#{room.id}
                  #                   &user_id=#{current_user.id}
                  #                   &auth_token=#{current_user.authentication_token}
                  #                   &type=#{type}
                  #                   &source_id=#{source_id}
                  #                   &lock=#{current_user.id == room.presenter_user.id}
                  #                   &interactive=#{room.service_type == 'webrtcservice'}",
                  #         data: {initialization_type: initialization_type, roomid: room.id, now: Time.now.to_i, start_at: start_at},
                  #         style: 'display: none',
                  #         title: title,
                  #         class: link_css_classes)
                  link_to('Join',
                          spa_room_path(room.id),
                          data: { initialization_type: initialization_type, roomid: room.id, now: Time.now.to_i,
                                  start_at: start_at },
                          style: 'display: none',
                          title: title,
                          class: link_css_classes)
                elsif type == 'livestream'
                  link_to('Join',
                          abstract_session.relative_path,
                          data: { initialization_type: initialization_type, roomid: room.id, now: Time.now.to_i,
                                  start_at: start_at },
                          style: 'display: none',
                          title: title,
                          class: link_css_classes)
                else
                  if type == 'in_progress'
                    button_text = 'In progress'
                    onclick_value = 'return false'
                  else
                    button_text = 'Join'
                    onclick_value = join_as_participant_onclick_value(room, (type == 'immersive'), source_id)
                  end
                  link_to(button_text,
                          '#',
                          onclick: onclick_value,
                          data: { initialization_type: initialization_type, now: Time.now.to_i, start_at: start_at,
                                  presenter: presenter, roomid: room.id },
                          style: 'display: none',
                          title: title,
                          class: link_css_classes)
                end

    html_link = make_sure_email_is_confirmed(html_link)

    OpenStruct.new(html_link: html_link, onclick_value: onclick_value)
  end

  def temporary_except_livestream?(type)
    if Rails.env.production? || Rails.env.qa?
      type == 'immersive'
    else
      type != 'in_progress'
    end
  end

  private

  # Does not allow users without confirmed emails to join
  # @return [String]
  def make_sure_email_is_confirmed(link_html_code)
    return link_html_code if current_user.blank? || current_user.confirmed?

    link_html_code.tap do |result|
      if result.include?('onclick')
        result.gsub!(/onclick\=\"[^"]*\"/,
                     %(onclick="alert('#{I18n.t('video.can_not_join_before_email_confirmation_message')}'); return false"))
      end
    end
  end

  def join_as_participant_onclick_value(room, _lobby = true, _source_id = nil)
    existence_path = Rails.application.class.routes.url_helpers.room_existence_lobby_path(room.id)
    show_page_path = if room.abstract_session.device_type == 'zoom'
                       if room.abstract_session.zoom_meeting.present?
                         if can?(:join_as_participant, room.abstract_session)
                           room.abstract_session.zoom_meeting.join_url
                         elsif can?(:join_as_presenter, room.abstract_session)
                           room.abstract_session.zoom_meeting.start_url
                         end
                       else
                         # root_url
                         spa_room_path(room.id)
                         #  lobby ? Rails.application.class.routes.url_helpers.lobby_path(room.id, source_id: source_id) : Rails.application.class.routes.url_helpers.livestream_path(room.id)
                       end
                     else
                       spa_room_path(room.id)
                       #  lobby ? Rails.application.class.routes.url_helpers.lobby_path(room.id, source_id: source_id) : Rails.application.class.routes.url_helpers.livestream_path(room.id)
                     end
    # TODO: get rid of sync xhr request - talk to Alex about better solution.
    %{
    try{
    lastPlayer.pause();
    lastPlayer.muted = true;
    }catch(e){};
    var isRoomExists = true;
    var message = '';
    $.ajax({
      url: "#{existence_path}",
      async: false
    }).fail(function(response){ message = response.responseJSON.message; isRoomExists = false; });
    if(isRoomExists){
      window.open('#{show_page_path}',
                  '#{I18n.t('assets.javascripts.session.join_btn_on_click')}',
                  'width=' + parseInt(screen.width - screen.width * 0.1) + ',
                  height=' + parseInt(screen.height - screen.height * 0.1) + ',
                  resizable=yes,
                  top='+ parseInt(screen.height * 0.1 / 2) +',
                  left=' + parseInt(screen.width * 0.1 / 2) + ',
                  scrollbars=yes,
                  status=no,
                  menubar=no,
                  toolbar=no,
                  location=no,
                  directories=no');
    }else{
      $.showFlashMessage(message, {type: "error"});
    }
  }.squish
  end
end
