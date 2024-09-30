# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  extend Mailboxer::Models::Messageable::ActiveRecordExtension
end
Rails.application.config.to_prepare do
  Mailboxer.setup do |config|
    # Configures if you application uses or not email sending for Notifications and Messages
    config.uses_emails = true

    # Configures the default from for emails sent for Messages and Notifications
    config.default_from = Rails.application.credentials.global[:mailer_from] or raise 'mailer.from must be present in config'

    # Configures the methods needed by mailboxer
    config.email_method = :mailboxer_email
    config.name_method = :name

    # Configures if you use or not a search engine and which one you are using
    # Supported engines: [:solr,:sphinx]
    config.search_enabled = false
    config.search_engine = :solr

    config.notification_mailer = :noop
    config.message_mailer = MessageMailer
  end
end
