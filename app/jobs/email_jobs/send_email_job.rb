# frozen_string_literal: true

class EmailJobs::SendEmailJob < ApplicationJob
  sidekiq_options queue: :critical

  def perform(user_id, contact_ids, content, subject, template = Mailing::Template::GENERAL[:id], layout = Mailing::Template::GENERAL[:id])
    user = User.find_by(id: user_id)

    return if user.nil?

    user.contacts.where(id: contact_ids).find_each do |contact|
      replacements = { '[username]' => contact.name }
      Mailer.custom_email(email: contact.email, content: content, subject: subject, replacements: replacements,
                          template: template, layout: layout).deliver_later
    end
  end
end
