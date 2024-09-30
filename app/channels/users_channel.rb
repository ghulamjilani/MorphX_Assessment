# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  EVENTS = {
    'join-member': 'Notifies user to join livestream(API server). Data: { user_id: user_id, stream_id: room.stream_name, token: "", url: url, room_id: room.id }',
    'new-flashbox': 'User received new invitation to Company/Session/Channel. Data: {flashbox: flashbox_html, notifications: blocking_notifications.notifications}',
    'new-notification': 'New notification to user created. Data: { count: user.reminder_notifications.unread.count, id: notification.id, subject: notification.subject, body: notification.body, created_at: notification.created_at, unread: true, sender_data: sender_data }',
    'backstage-update-join': 'User invited to join backstage. Data: { message: "Presenter {@room.presenter_user.public_display_name} has invited you to join him backstage", room_id: @room.id, now: Time.now.to_i, start_at: @room.actual_start_at.to_i}',
    confirmed: 'User confirmed. Used for preview purchase modal to refresh unconfirmed email. Data: {user_id: id}',
    new_contact: 'New contact added for user. Data: { id: contact.id, name: contact.name, email: contact.email, status: contact.status, contact_user_id: contact.contact_user_id, contact_user: { id: contact.contact_user&.id, public_display_name: contact.contact_user&.public_display_name, relative_path: contact.contact_user&.relative_path, avatar_url: contact.contact_user&.avatar_url } }',
    'unread-messages-count': 'New message to user created. Data: @recipient.unread_messages_count',
    'new-blog-comment': 'User received new comment. Data: { comment: { id: id, body_preview: (body.length < 33 ? body : body.first(32).strip + "…"), }, user: { id: user_id, public_display_name: user.public_display_name, avatar_url: user.avatar_url, relative_path: user.relative_path }, post: { id: post.id, title: post.title, }, commentable: { id: commentable_id, type: commentable_type, body_preview: (commentable.body.length < 33 ? commentable.body : commentable.body.first(32).strip + "…") } }'
  }.freeze

  def subscribed
    stream_from 'users_channel'
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
