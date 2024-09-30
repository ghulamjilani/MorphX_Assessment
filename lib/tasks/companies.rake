# frozen_string_literal: true

task 'companies:create' => :environment do
  Channel.find_each do |channel|
    puts "Processing channel ##{channel.id}"
    if channel.presenter
      user = channel.presenter.user
      unless user.organization
        puts 'Create Organization'
        user.create_organization(name: '')
      end
      channel.update_attribute(:organization_id, user.organization.id)
    else
      puts 'No presenter found, checking organization...'
      if channel.organization
        puts 'Organization found'
      else
        puts "CHECK: No organization and presenter on channel ##{channel.id}"
      end
    end
  end
end
