# frozen_string_literal: true

envelope json do
  json.organizations do
    json.array! @organizations do |organization|
      json.organization do
        json.partial! 'organization', organization: organization
      end
      json.user do
        json.partial! 'api/v1/public/users/user_short', model: organization.user
      end
    end
  end
end
