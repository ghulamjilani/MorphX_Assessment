# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                                                  model.id
  json.user_id                                             model.user_id
end
