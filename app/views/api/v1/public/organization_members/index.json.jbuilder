# frozen_string_literal: true

envelope json do
  json.organization_members do
    json.array! @organization_members do |member|
      json.partial! 'api/v1/public/users/user_short', model: member
    end
  end
end
