# frozen_string_literal: true

envelope json do
  json.organization_memberships do
    json.array! @organization_memberships do |organization_membership|
      json.organization_membership do
        json.partial! 'organization_membership', organization_membership: organization_membership
      end
    end
  end
end
