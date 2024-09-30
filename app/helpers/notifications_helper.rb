# frozen_string_literal: true

module NotificationsHelper
  def new_notification_class(notification)
    'new_Notifications' unless notification_read?(notification)
  end

  def active_notification_class(notification)
    'active' if notification_read?(notification)
  end

  def notification_read?(notification)
    Rails.cache.fetch("notification_read/#{notification.cache_key}/#{current_user.cache_key}") do
      !!notification.receipts.find do |r|
        r.receiver_id == current_user.id && r.receiver_type == current_user.class.to_s
      end.try(:is_read?)
    end
  end
end
