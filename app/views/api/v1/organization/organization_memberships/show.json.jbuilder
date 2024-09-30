# frozen_string_literal: true

envelope json, (@status || 200), (@organization_membership.pretty_errors if @organization_membership.errors.present?) do
  json.organization_membership do
    json.partial! 'organization_membership', organization_membership: @organization_membership
  end
end
