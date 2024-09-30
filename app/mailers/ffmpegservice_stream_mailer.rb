# frozen_string_literal: true

class FfmpegserviceStreamMailer < ApplicationMailer
  include Devise::Mailers::Helpers

  def stream_stopped(ffmpegservice_account_id, stopped_at)
    wa = FfmpegserviceAccount.find(ffmpegservice_account_id)
    @stream_id = wa.stream_id
    @stopped_at = stopped_at

    @user = wa.user.presence || wa.organization.user
    @subject = I18n.t('mailers.ffmpegservice_stream.stream_stopped.subject',
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
