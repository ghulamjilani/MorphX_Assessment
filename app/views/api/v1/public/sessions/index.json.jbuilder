# frozen_string_literal: true

envelope json do
  json.sessions do
    json.array! @sessions do |session|
      json.session do
        json.partial! 'session_short', model: session
      end
      json.presenter do
        json.partial! 'api/v1/public/presenters/presenter_short', model: session.presenter
      end
      json.presenter_user do
        json.partial! 'api/v1/public/users/user_short', model: session.presenter.user
      end
    end
  end
end
