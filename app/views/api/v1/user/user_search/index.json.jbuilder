# frozen_string_literal: true

envelope json do
  json.users do
    json.array! @users do |user|
      json.user do
        json.partial! 'user', user: user
      end
    end
  end
end
