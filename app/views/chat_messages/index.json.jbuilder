# frozen_string_literal: true

json.array! @chat_messages do |chat_message|
  json.extract! chat_message, :body, :position, :user_id
  json.id chat_message.id.to_s
  json.offset chat_message.created_at.to_i - @became_active_at.to_i
end
