# frozen_string_literal: true

class RecordingMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def you_obtained_access(recording_id, user_id, transaction_id)
    @user = User.find(user_id)
    @recording = Recording.find(recording_id)
    @direct_from_name = @recording.channel.title

    @payment_transaction = transaction_id ? PaymentTransaction.find(transaction_id) : nil

    @subject = 'Thank you for purchasing upload'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def ready(recording_id)
    @recording = Recording.find(recording_id)
    @user = @recording.organizer
    @subject = I18n.t('mailers.recording.ready.subject',
                      service_name: Rails.application.credentials.global[:service_name])
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end
end
