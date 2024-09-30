# frozen_string_literal: true

class ListMailer < ApplicationMailer
  include Devise::Mailers::Helpers

  def list_shared(user_id, list_id)
    @user = User.find(user_id)
    @list = List.find(list_id)

    @subject = "Product list #{@list.name} shared with you"
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: @list.user,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end
end
