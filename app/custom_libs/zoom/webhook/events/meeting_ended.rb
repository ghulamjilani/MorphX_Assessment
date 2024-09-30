# frozen_string_literal: true

# {
#   "event" => "meeting.ended",
#   "payload" => {
#     "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#     "object" => {
#       "duration" => 55,
#       "start_time" => "2021-02-01T09:00:43Z",
#       "timezone" => "Europe/Kiev",
#       "end_time" => "2021-02-01T09:10:22Z",
#       "topic" => "Morning Meeting",
#       "id" => "84986870978",
#       "type" => 2,
#       "uuid" => "sxa9wbF8RQ+J/5yfOHRuTw==",
#       "host_id" => "OdT9FmVRSg6epnzDHUm2vw" } },
#   "event_ts" => 1612170622119,
#   "controller" => "webhook/v1/zoom",
#   "action" => "create",
#   "zoom" => {
#     "event" => "meeting.ended",
#     "payload" => {
#       "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#       "object" => {
#         "duration" => 55,
#         "start_time" => "2021-02-01T09:00:43Z",
#         "timezone" => "Europe/Kiev",
#         "end_time" => "2021-02-01T09:10:22Z",
#         "topic" => "Morning Meeting",
#         "id" => "84986870978",
#         "type" => 2,
#         "uuid" => "sxa9wbF8RQ+J/5yfOHRuTw==",
#         "host_id" => "OdT9FmVRSg6epnzDHUm2vw" } },
#     "event_ts" => 1612170622119 } }

class Zoom::Webhook::Events::MeetingEnded < Zoom::Webhook::Base
  @event_type = 'meeting.ended'

  def perform
    puts @event
    meeting = ZoomMeeting.find_by(meeting_id: @event['payload']['object']['uuid'])
    if meeting
      session = meeting.session
      room = session.room
      PrivateLivestreamRoomsChannel.broadcast_to room, event: 'livestream-down', data: { active: false }
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'livestream-down', data: { active: false }
      # session.update_attributes(stopped_at: @event['payload']['object']['end_time'])
      room.update(livestream_up: false, status: Room::Statuses::CLOSED)
      session.service_status_off!
      Control::Room.new(room).stop
      room.abstract_session.update_columns(stop_reason: 'webhook_ended')
    end
  end
end
