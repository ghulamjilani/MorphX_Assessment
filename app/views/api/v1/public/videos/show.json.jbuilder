# frozen_string_literal: true

envelope json, (@status || 200), (@video.pretty_errors if @video.errors.present?) do
  json.video do
    json.partial! 'video', model: @video
  end
  json.abstract_session do
    json.partial! 'api/v1/public/sessions/session_short', model: @video.room.abstract_session
  end
  json.organizer do
    json.partial! 'api/v1/public/users/user_short', model: @video.user
  end
  if @video.polls.enabled.first.present?
    json.poll do
      json.partial! 'api/v1/public/poll/polls/poll', poll: @video.polls.enabled.first
    end
  end
  json.polls do
    json.array! @video.session.polls.order(created_at: :asc) do |poll|
      json.partial! 'api/v1/public/poll/polls/poll', poll: poll
    end
  end
end
