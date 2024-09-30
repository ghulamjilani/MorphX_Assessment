# frozen_string_literal: true

envelope json do
  json.array! @users do |user|
    if user.parent_organization_id == current_organization.id
      json.partial! 'user', user: user
    else
      json.partial! 'api/v1/public/users/user_short', model: user
    end
  end
end
