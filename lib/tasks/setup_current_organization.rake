# frozen_string_literal: true

namespace :current_organization do
  desc 'Update current_organization for all users'
  task setup: :environment do
    User.find_each do |user|
      if user.current_organization_id? && (user.valid? || !user.errors.has_key?(:current_organization_id))
        next
      end

      new_organization_id = user.all_organizations.pluck(:id).first
      unless user.current_organization_id.blank? && new_organization_id.blank?
        user.update_column(:current_organization_id,
                           new_organization_id)
      end
    end
  end
end
