# frozen_string_literal: true

envelope json do
  json.credentials do
    json.array! @credentials do |credential|
      json.partial! 'api/v1/user/access_management/groups/credential', credential: credential
    end
  end
end
