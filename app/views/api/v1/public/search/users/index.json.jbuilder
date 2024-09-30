# frozen_string_literal: true

envelope json do
  json.users do
    json.array! @users do |user|
      json.partial! 'api/v1/public/users/index_item', user: user
    end
  end
end
