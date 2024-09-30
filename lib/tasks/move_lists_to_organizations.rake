# frozen_string_literal: true

task 'lists:move_to_org' => :environment do
  List.find_each do |list|
    puts "Processing list ##{list.id}"
    if list.user.organization.present?
      list.update(organization_id: list.user.organization.id)
    else
      puts "List user without org ##{list.id}. Destroying"
      list.destroy
    end
  end
end
