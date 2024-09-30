# frozen_string_literal: true

# {
#   "payload" => {
#     "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#     "object" => {
#       "uuid" => "UnkLIH0cRvCBvxgN0RezbQ==",
#       "participant" => {
#         "leave_time" => "2021-01-29T14:28:23Z",
#         "user_id" => "16778240",
#         "user_name" => "Daryna Varankover",
#         "id" => "OdT9FmVRSg6epnzDHUm2vw",
#         "email" => "stdashulya@gmail.com" },
#       "id" => "9206225653",
#       "type" => 4,
#       "topic" => "Daryna Varankover's Personal Meeting Room",
#       "host_id" => "OdT9FmVRSg6epnzDHUm2vw",
#       "duration" => 0,
#       "start_time" => "2021-01-29T14:18:01Z",
#       "timezone" => "Europe/Kiev" } },
#   "event_ts" => 1611930506066,
#   "event" => "meeting.participant_left",
#   "controller" => "webhook/v1/zoom",
#   "action" => "create",
#   "zoom" => {
#     "payload" => {
#       "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#       "object" => {
#         "uuid" => "UnkLIH0cRvCBvxgN0RezbQ==",
#         "participant" => {
#           "leave_time" => "2021-01-29T14:28:23Z",
#           "user_id" => "16778240",
#           "user_name" => "Daryna Varankover",
#           "id" => "OdT9FmVRSg6epnzDHUm2vw",
#           "email" => "stdashulya@gmail.com" },
#         "id" => "9206225653",
#         "type" => 4,
#         "topic" => "Daryna Varankover's Personal Meeting Room",
#         "host_id" => "OdT9FmVRSg6epnzDHUm2vw",
#         "duration" => 0,
#         "start_time" => "2021-01-29T14:18:01Z",
#         "timezone" => "Europe/Kiev" } },
#     "event_ts" => 1611930506066,
#     "event" => "meeting.participant_left" } }

class Zoom::Webhook::Events::MeetingParticipantLeft < Zoom::Webhook::Base
  @event_type = 'meeting.participant_left'

  def perform
  end
end
