# frozen_string_literal: true

# {
#   "event" => "meeting.started",
#   "payload" => {
#     "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#     "object" => {
#       "duration" => 0,
#       "start_time" => "2021-01-29T14:18:01Z",
#       "timezone" => "Europe/Kiev",
#       "topic" => "Daryna Varankover's Personal Meeting Room",
#       "id" => "9206225653",
#       "type" => 4,
#       "uuid" => "UnkLIH0cRvCBvxgN0RezbQ==",
#       "host_id" => "OdT9FmVRSg6epnzDHUm2vw" } },
#   "event_ts" => 1611929881931,
#   "controller" => "webhook/v1/zoom",
#   "action" => "create",
#   "zoom" => {
#     "event" => "meeting.started",
#     "payload" => {
#       "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#       "object" => {
#         "duration" => 0,
#         "start_time" => "2021-01-29T14:18:01Z",
#         "timezone" => "Europe/Kiev",
#         "topic" => "Daryna Varankover's Personal Meeting Room",
#         "id" => "9206225653",
#         "type" => 4,
#         "uuid" => "UnkLIH0cRvCBvxgN0RezbQ==",
#         "host_id" => "OdT9FmVRSg6epnzDHUm2vw" } },
#     "event_ts" => 1611929881931 } }

class Zoom::Webhook::Events::MeetingStarted < Zoom::Webhook::Base
  @event_type = 'meeting.started'

  def perform
    puts @event
    meeting = ZoomMeeting.find_by(meeting_id: @event['payload']['object']['uuid'])
    if meeting
      session = meeting.session
      room = session.room
      Control::Room.new(room).start
      room.update(livestream_up: true, status: Room::Statuses::ACTIVE)
      session.service_status_up!
      PrivateLivestreamRoomsChannel.broadcast_to room, event: 'livestream-up', data: { active: room.active? }
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'livestream-up', data: { active: room.active? }
      SessionsChannel.broadcast 'livestream-up', { session_id: room.abstract_session_id, active: room.active? }
    end
  end
end
