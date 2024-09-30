# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  self.delivery_job = ApplicationMailDeliveryJob
  # default from: "from@example.com"
  include MailerConcerns::MailboxerHelper #FIXMERAILS7

  layout 'email'
  helper  MailerHelper
  include  MailerHelper
  append_view_path Rails.root.join('app', 'views', 'mailers')

  def enabled_smtp_options
    {
      user_name: ENV['UNITE_SMTP_USERNAME'].presence || ENV['SMTP_USERNAME'],
      password: ENV['UNITE_SMTP_PASSWORD'].presence || ENV['SMTP_PASSWORD']
    }
  end
end
