# frozen_string_literal: true

json.array! @conversations do |conversation|
  last_message = conversation.last_message

  json.id = conversation.id
  json.extract! last_message, :body, :created_at

  _subject = link_to(conversation.subject,
                     preview_modal_conversation_path(conversation.id),
                     method: :get,
                     remote: true,
                     style: 'visibility: visible')

  json.subject _subject

  json.sender last_message.sender.public_display_name

  json.avatar user_with_avatar(last_message.sender)

  json.unread conversation.is_unread?(current_user)
end
