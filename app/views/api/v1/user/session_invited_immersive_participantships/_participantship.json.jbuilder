# frozen_string_literal: true

json.cache! participantship, expires_in: 1.day do
  json.extract! participantship, :id, :status, :session_id
end
