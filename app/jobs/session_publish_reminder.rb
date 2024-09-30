# frozen_string_literal: true

class SessionPublishReminder < ApplicationJob
  def perform(session_id)
    session = Session.find(session_id)

    return if session.published?
    return if session.started?
    return if session.cancelled?
    return if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING
    return if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

    SessionMailer.publish_reminder(session.id).deliver_later
  end
end
