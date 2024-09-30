# frozen_string_literal: true

envelope json do
  json.array! @organizations do |organization|
    json.id organization.id
    json.name organization.name
  end
end
