# frozen_string_literal: true

class SessionJobs::ZoomMeeting < ApplicationJob
  def perform(id)
    session = Session.find id
    connected_zoom_account = session.organizer.zoom_identity
    raise 'No Zoom Account found' if connected_zoom_account.blank?

    sender = Sender::ZoomLib.new(identity: connected_zoom_account)
    zoom_user = sender.user
    raise 'Zoom Account is Basic' if zoom_user[:type].to_i < 2 && !Rails.env.development?

    zoom_session_params = {
      topic: session.title,
      type: 1,
      agenda: session.description,
      settings: {
        auto_recording: (session.recorded_delivery_method? ? 'cloud' : 'none')
      }
    }
    meeting = sender.create_meeting(zoom_session_params)
    zoom_meeting = ZoomMeeting.find_or_initialize_by(session_id: session.id)
    zoom_meeting.meeting_id = meeting[:id]
    zoom_meeting.registration_url = meeting[:registration_url]
    zoom_meeting.start_url = meeting[:start_url]
    zoom_meeting.join_url = meeting[:join_url]
    zoom_meeting.password = meeting[:password]
    zoom_meeting.save
  rescue StandardError => e
    Airbrake.notify("SessionJobs::ZoomMeeting #{e.message}", parameters: {
                      id: id
                    })
  end
end
