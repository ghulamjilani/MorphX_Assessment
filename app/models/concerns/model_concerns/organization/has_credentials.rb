# frozen_string_literal: true

module ModelConcerns::Organization::HasCredentials
  extend ActiveSupport::Concern

  def users_ids_with_credentials(credential_codes)
    Rails.cache.fetch("organization/#{__method__}/#{cache_key}/#{credential_codes}") do
      user_ids = OrganizationMembership.active
                                       .joins(:credentials)
                                       .where.not(access_management_credentials: { code: ::AccessManagement::Credential::Codes.inactive })
                                       .where(organization_id: id, access_management_credentials: { is_enabled: true, code: credential_codes })
                                       .pluck(:user_id)
      user_ids << user_id
      user_ids
    end
  end
end
