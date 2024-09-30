# frozen_string_literal: true

require 'mailboxer'

module Immerss
  module Mailboxer
    class Notification
      # @return [Mailboxer::Notification]
      def self.save_with_receipt(user:, subject:, body:, sender:)
        ::Mailboxer::Notification.create(
          subject: subject,
          body: body,
          sender: sender,
          notified_object: user,
          created_at: Time.zone.now # expires: session.start_at)
        ).tap do |notification|
          Rails.cache.delete(user.new_notifications_count_cache_key)

          receipt = ::Mailboxer::Receipt.new
          receipt.notification = notification
          receipt.is_read = false
          receipt.receiver = user
          receipt.save!

          sender_data = {
            name: sender ? sender.public_display_name : Rails.application.credentials.global[:service_name],
            path: sender ? sender.relative_path : '#',
            avatar: sender ? sender.avatar_url : false # TODO: find solution to show ActionView::Helpers::AssetUrlHelper.image_url('ImmerssNotificationAvatar.jpg')
          }

          UsersChannel.broadcast_to(user, event: 'new-notification', data: {
                                      count: user.reminder_notifications.unread.count,
                                      id: notification.id,
                                      subject: notification.subject,
                                      body: notification.body,
                                      created_at: notification.created_at,
                                      unread: true,
                                      sender_data: sender_data
                                    })
        end
      end
    end
  end
end
