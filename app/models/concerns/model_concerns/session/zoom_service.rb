# frozen_string_literal: true

module ModelConcerns::Session::ZoomService
  extend ActiveSupport::Concern

  def create_zoom_meeting
    connected_zoom_account = organizer.zoom_identity
    raise 'No Zoom Account found' if connected_zoom_account.blank?

    sender = Sender::ZoomLib.new(identity: connected_zoom_account)
    zoom_user = sender.user
    raise 'Zoom Account is Basic' if zoom_user[:type].to_i < 2 && !Rails.env.development?

    timezone = organizer.timezone
    start_time = if start_now
                   3.seconds.from_now
                 else
                   start_at
                 end
    start_time = if timezone.blank?
                   start_time.strftime('%FT%T:00Z')
                 else
                   start_time.in_time_zone(timezone).strftime('%FT%T')
                 end
    zoom_session_params = {
      topic: title,
      type: 2,
      start_time: start_time,
      agenda: description,
      duration: duration,
      timezone: timezone,
      settings: {
        jbh_time: 0, # Allow participant to join anytime.
        approval_type: 1, # Manually approve.
        auto_recording: (recorded_delivery_method? ? 'cloud' : 'none')
      }
    }
    meeting = sender.create_meeting(zoom_session_params)
    zoom_meeting = ZoomMeeting.find_or_initialize_by(session_id: id)
    zoom_meeting.meeting_id = meeting[:uuid]
    zoom_meeting.registration_url = meeting[:registration_url]
    zoom_meeting.start_url = meeting[:start_url]
    zoom_meeting.join_url = meeting[:join_url]
    zoom_meeting.password = meeting[:password]
    zoom_meeting.save
  end
end
