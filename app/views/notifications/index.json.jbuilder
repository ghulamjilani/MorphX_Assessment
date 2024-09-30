# frozen_string_literal: true

json.array! @notifications do |notification|
  json.extract! notification, :id, :subject, :body, :created_at
  json.sender notification.sender ? notification.sender.public_display_name : Rails.application.credentials.global[:service_name]

  json.avatar user_with_avatar(notification.sender)

  json.sender_data sender_data(notification.sender)

  json.unread !notification_read?(notification)
end
