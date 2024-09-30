# frozen_string_literal: true

envelope json, (@status || 200), @session.pretty_errors.presence do
  json.session do
    json.partial! '/api/v1/user/sessions/session', session: @session

    json.session_duration do
      json.change_by                  @change_by
      json.duration_change_times_left @session.duration_change_times_left
      json.duration_available_max     @session.duration_available_max
    end
  end
end
