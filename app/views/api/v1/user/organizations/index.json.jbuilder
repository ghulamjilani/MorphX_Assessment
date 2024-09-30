# frozen_string_literal: true

envelope json do
  json.organizations do
    json.array! @organizations do |organization|
      json.partial! 'organization', organization: organization
    end
  end
end
