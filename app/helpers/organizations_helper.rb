# frozen_string_literal: true

module OrganizationsHelper
  def display_avatar_for_organizational_channel?(_channel)
    Rails.env.development?
  end

  def display_company_three_dots_dropdown?
    !Rails.env.production?
  end

  def display_company_executives_team_link?
    !Rails.env.production?
  end

  def organization_cover_url(organization)
    organization.cover&.image&.url || asset_path('channels/default_cover.png')
  end
end
