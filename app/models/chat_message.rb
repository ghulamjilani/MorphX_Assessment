# frozen_string_literal: true

class ChatMessage
  include Mongoid::Document

  store_in collection: 'chat_messages'

  field :user_id, type: String # An id of user - an author of message
  field :user_type, type: String # Type of user - an author of message
  field :position, type: Integer # A position of message in messages chain
  field :webrtcservice_id, type: String
  field :created_at, type: Time
  field :updated_at, type: Time
  field :edited, type: Boolean # Whether a message was edited
  field :body, type: String # Contains serialized JSON
  field :last_updated_by, type: Integer # An id of user who edited a message

  belongs_to :chat_channel

  index(chat_channel_id: 1)
  index(position: 1)
  index({ webrtcservice_id: 1 }, { unique: true })
  index(_id: 'hashed')
end
