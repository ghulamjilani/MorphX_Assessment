# frozen_string_literal: true

# {
#   "event" => "meeting.deleted",
#   "payload" => {
#     "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#     "operator" => "stdashulya@gmail.com",
#     "operator_id" => "OdT9FmVRSg6epnzDHUm2vw",
#     "object" => {
#       "uuid" => "bK2L5KuSRJuGn2n2J2v+pw==",
#       "id" => 82585365622,
#       "host_id" => "OdT9FmVRSg6epnzDHUm2vw",
#       "topic" => "Cynthia Davis Live Session",
#       "type" => 2,
#       "start_time" => "2021-01-29T13:00:00Z",
#       "duration" => 60,
#       "timezone" => "Europe/Kiev" } },
#   "event_ts" => 1611925568519,
#   "controller" => "webhook/v1/zoom",
#   "action" => "create",
#   "zoom" => {
#     "event" => "meeting.deleted",
#     "payload" => {
#       "account_id" => "zI8tjMxnTHmSj0vLMQ1_wA",
#       "operator" => "stdashulya@gmail.com",
#       "operator_id" => "OdT9FmVRSg6epnzDHUm2vw",
#       "object" => {
#         "uuid" => "bK2L5KuSRJuGn2n2J2v+pw==",
#         "id" => 82585365622,
#         "host_id" => "OdT9FmVRSg6epnzDHUm2vw",
#         "topic" => "Cynthia Davis Live Session",
#         "type" => 2,
#         "start_time" => "2021-01-29T13:00:00Z",
#         "duration" => 60,
#         "timezone" => "Europe/Kiev" } },
#     "event_ts" => 1611925568519 } }

class Zoom::Webhook::Events::MeetingDeleted < Zoom::Webhook::Base
  @event_type = 'meeting.deleted'

  def perform
    puts @event
    meeting = ZoomMeeting.find_by(meeting_id: @event['payload']['object']['uuid'])
    if meeting
      session = meeting.session
      reason = AbstractSessionCancelReason.find_by(name: 'Unforseen reasons') || AbstractSessionCancelReason.first
      interactor = SessionCancellation.new(session, reason)
      unless interactor.execute
        Airbrake.notify('Zoom Webhook (Meeting deleted) Session cancellation failed',
                        parameters: { session_id: session.id, event: @event })
      end
    end
  end
end
