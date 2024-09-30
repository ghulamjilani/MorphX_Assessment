# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/sessions/_index_item', session], expires_in: 1.day do
  json.session do
    json.partial! 'session', session: session
  end
  json.user do
    json.partial! 'api/v1/public/calendar/users/user', user: session.presenter.user
  end
end
