# frozen_string_literal: true

class EmailJobs::SendTimeToServiceEmailJob < ApplicationJob
  sidekiq_options queue: :critical

  def perform(user_id, contact_ids, content, subject)
    user = User.find_by(id: user_id)

    return if user.nil?

    contacts = user.contacts.where(id: contact_ids)
    contacts.each do |contact|
      replacements = { '[username]' => contact.name }
      Mailer.custom_email(email: contact.email, content: content, subject: subject, replacements: replacements,
                          template: 'email_general', layout: 'email').deliver_later
      Mailer.custom_email(email: contact.email, content: '',
                          subject: I18n.t('mailers.dashboard.subject', service_name: Rails.application.credentials.global[:service_name]), template: 'new_site_email_for_existing_users', layout: 'email').deliver_later
      # Mailer.time_to_service(from_user_id: user.id, email: contact.email, user_name: contact.name).deliver_later
    end
  end
end
