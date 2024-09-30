# frozen_string_literal: true

namespace :user do
  desc "Fix current organization, i.e.: 'rake user:fix_current_organization[62]' will fix current_organization_id for user #62"
  task :fix_current_organization, [:user_id] => :environment do |_task, args|
    users = if args[:user_id].blank?
              User.joins('LEFT JOIN organizations ON organizations.user_id = users.id')
                  .joins("LEFT JOIN organization_memberships ON organization_memberships.user_id = users.id AND organization_memberships.status = 'active'")
                  .where(current_organization_id: nil)
                  .where('(organizations.id IS NOT NULL) OR (organization_memberships.id IS NOT NULL)')
            else
              User.where(id: args[:user_id])
            end

    total_count = users.count
    p "Found #{total_count} users with blank current_organization"

    users.find_each.with_index do |user, index|
      p "User ##{user.id}(#{index + 1}/#{total_count})"
      (p 'user is valid' and next) if user.valid?
      p "current_organization_id was: #{user.current_organization_id || 'NULL'}"
      # p 'current_organization is BLANK' if user.current_organization_id && user.current_organization.blank?
      new_id = user.all_organizations.pick(:id)
      p "new current_organization_id: #{new_id || 'NULL'}"
      user.update_column(:current_organization_id, new_id)
    end
  end
end
