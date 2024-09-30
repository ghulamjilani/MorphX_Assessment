# frozen_string_literal: true

envelope json, (@status || 200), (@organization.pretty_errors if @organization.errors.present?) do
  json.organization do
    json.partial! 'organization', organization: @organization
  end
end
