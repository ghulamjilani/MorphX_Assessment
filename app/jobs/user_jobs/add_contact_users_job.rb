# frozen_string_literal: true

module UserJobs
  class AddContactUsersJob < ApplicationJob
    def perform(user_id, emails)
      user = User.find user_id
      emails = emails.flatten.compact_blank.map { |email| email.to_s.downcase }.uniq

      existing_emails = user.contacts.where(email: emails).pluck(:email)
      new_emails = emails - existing_emails
      new_emails.each do |email|
        next unless (contact_user = User.find_by(email: email))

        contact_user.valid?
        next if contact_user.errors[:email].present?

        user.contacts.create(contact_user_id: contact_user.id, email: contact_user.email, name: contact_user.public_display_name)
      rescue StandardError => e
        Airbrake.notify("UserJobs::AddContactsJob #{e.message}",
                        parameters: {
                          user_id: user_id,
                          email: email
                        })
      end
    end
  end
end
