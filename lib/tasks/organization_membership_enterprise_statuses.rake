# frozen_string_literal: true

namespace :organization_membership do
  desc 'Update organization_membership statuses for all users on enterprise'
  task enterprise_statuses: :environment do
    if Rails.application.credentials.global[:enterprise]
      OrganizationMembership.pending.find_each do |organization_membership|
        organization_membership.active! if organization_membership.user.user_info_ready?
      end
    end
  end
end
