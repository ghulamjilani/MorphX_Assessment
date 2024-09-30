# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/presenters/_presenter_short', model], expires_in: 1.day do
  json.id                                                  model.id
  json.user_id                                             model.user_id
end
