# frozen_string_literal: true

envelope json, (@status || 200), (@session.pretty_errors if @session.errors.present?) do
  json.session do
    json.partial! 'session', model: @session
  end
  json.videos do
    json.array! @session.records do |video|
      json.video do
        json.partial! 'api/v1/public/videos/video', model: video
      end
    end
  end
  json.polls do
    json.array! @session.polls.order(created_at: :asc) do |poll|
      json.partial! 'api/v1/public/poll/polls/poll', poll: poll
    end
  end
end
