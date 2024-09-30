# frozen_string_literal: true

module ModelConcerns::Organization::HasCreators
  extend ActiveSupport::Concern

  def creators_count
    Rails.cache.fetch("organization/#{__method__}/#{cache_key}/") do
      count = OrganizationMembership.active
                                    .joins(:credentials)
                                    .where(organization_id: id, access_management_credentials: { code: ::AccessManagement::Credential::Codes::START_SESSION })
                                    .count
      count + 1 # organization owner is counted too
    end
  end
end
