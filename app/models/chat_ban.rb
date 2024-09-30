# frozen_string_literal: true

class ChatBan
  include Mongoid::Document

  store_in collection: 'chat_bans'

  field :user_id, type: Integer
  field :channel_id, type: Integer
  field :banned_id, type: String
  field :banned_type, type: String

  field :created_at, type: Time
  field :updated_at, type: Time
  field :ip_address, type: String
  field :user_agent, type: String

  index(_id: 'hashed')
end
