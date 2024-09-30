# frozen_string_literal: true

task 'companies:organizers:fix_presenters' => :environment do
  User.joins(%(LEFT JOIN organizations ON organizations.user_id = users.id))
      .joins(%(LEFT JOIN channels ON organizations.id = channels.organization_id))
      .joins(%(LEFT JOIN presenters ON users.id = presenters.user_id))
      .where.not(organizations: { user_id: nil }, channels: { listed_at: nil })
      .where(presenters: { user_id: nil }).distinct()
      .find_each do |user|
    puts ''
    puts "##{user.id} (#{user.display_name})"
    user.create_presenter
    puts 'User had no presenter. Presenter created.'
  end
end
