# frozen_string_literal: true

namespace :move_channels_to_organizations do
  desc 'Move channels association from user to company'
  task gogogo: :environment do
    Channel.where(organization_id: nil).find_each do |channel|
      organizer_user_id = if channel.organization_id.present?
                            channel.organization.user_id
                          elsif channel.presenter_id.present?
                            channel.presenter.user_id
                          end
      user = User.find_by(id: organizer_user_id)
      unless user
        puts "ERROR: No User found for Channel ##{channel.id} - #{channel.title}"
        next
      end
      organization = user.organization

      if organization.blank?
        organization = user.create_organization(name: user.public_display_name)
        puts "Organization #{organization.name} created"
      end
      channel.update(organization_id: organization.id, presenter_id: nil)
      puts "Channel ##{channel.id} - #{channel.title} successfully moved to #{organization.name}"
    end
  end
end
