# frozen_string_literal: true

task 'contacts:update' => :environment do
  Contact.find_each do |contact|
    puts "Processing contact ##{contact.id}"
    if contact.contact_user.present?
      contact.update(email: contact.contact_user.email, name: contact.contact_user.public_display_name)
    else
      puts "No user found for contact ##{contact.id}"
      contact.update_column(:contact_user_id, nil)
    end
  end
end
