# frozen_string_literal: true

class ChatChannel
  include Mongoid::Document

  store_in collection: 'chat_channels'

  field :session_id, type: Integer
  field :webrtcservice_id, type: String

  has_many :chat_messages

  index({ session_id: 1 }, { unique: true })
  index(_id: 'hashed')
end
