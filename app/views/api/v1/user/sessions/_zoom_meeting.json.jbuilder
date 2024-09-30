# frozen_string_literal: true

json.id session.zoom_meeting.id
if can?(:join_as_presenter, session)
  json.join_url session.zoom_meeting.start_url
elsif can?(:join_as_participant, session)
  json.join_url session.zoom_meeting.join_url
  json.password session.zoom_meeting.password
end
