# frozen_string_literal: true

class VideoMailer < ApplicationMailer
  include MailerConcerns::MailboxerHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def ready(video_id)
    @video = Video.find(video_id)
    @session = @video.room.abstract_session
    @user = @video.user
    @subject = I18n.t('mailers.video.ready.subject',
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

  def uploaded(video_id)
    @video = Video.find(video_id)
    @session = @video.room.abstract_session
    @user = @video.user
    @subject = I18n.t('mailers.video.upload.subject',
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

  def cleanup_notification(user_id:, video_ids:, time_interval:)
    @videos = Video.where(id: video_ids)
    @user = User.find_by(id: user_id)
    @time_interval = time_interval
    return if @user.nil?

    @subject = 'Some of your videos are scheduled to be removed'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail to: @user.email,
         subject: @subject,
         template_path: 'video_mailer',
         template_name: 'cleanup_notification'
  end
end
