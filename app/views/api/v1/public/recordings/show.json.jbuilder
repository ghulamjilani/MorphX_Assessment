# frozen_string_literal: true

envelope json, (@status || 200), (@recording.pretty_errors if @recording.errors.present?) do
  json.recording do
    json.partial! 'recording', model: @recording
  end

  json.organizer do
    org = @recording.organizer
    json.url                  org.relative_path
    json.public_display_name  org.public_display_name
  end

  if @recording.polls.enabled.first.present?
    json.poll do
      json.partial! 'api/v1/public/poll/polls/poll', poll: @recording.polls.enabled.first
    end
  end
end
