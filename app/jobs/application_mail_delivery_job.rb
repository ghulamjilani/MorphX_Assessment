# frozen_string_literal: true

class ApplicationMailDeliveryJob < ::ActionMailer::MailDeliveryJob
  sidekiq_options retry: 1
end
