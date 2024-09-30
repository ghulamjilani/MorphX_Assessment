# frozen_string_literal: true

envelope json, (@status || 200), (@notification.pretty_errors if @notification.errors.present?) do
  json.notification do
    json.partial! 'notification', notification: @notification
    json.sender do
      if @notification.sender.present?
        json.partial! '/api/v1/user/notifications/notification/sender', sender: @notification.sender
      else
        json.partial! '/api/v1/user/notifications/notification/default_sender'
      end
    end
  end
end
