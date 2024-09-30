# frozen_string_literal: true

class BlogMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def new_mention_in_post(post_id, mentioned_id)
    @post = Blog::Post.find(post_id)
    @user = User.not_fake.not_deleted.find(mentioned_id)
    @subject = I18n.t('mailers.blog.new_mention_in_post.subject',
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

  def new_mention_in_comment(comment_id, mentioned_id)
    @comment = Blog::Comment.find(comment_id)
    @user = User.not_fake.not_deleted.find(mentioned_id)
    @subject = I18n.t('mailers.blog.new_mention_in_comment.subject',
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
