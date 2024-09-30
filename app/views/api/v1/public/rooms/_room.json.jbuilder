# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                           model.id
  json.status                       model.status
  json.abstract_session_id          model.abstract_session_id
  json.abstract_session_type        model.abstract_session_type
end
