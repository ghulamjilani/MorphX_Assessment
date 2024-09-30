# frozen_string_literal: true

class ChatMember
  include Mongoid::Document

  store_in collection: 'chat_members'

  field :name, type: String
  field :location, type: String
  field :created_at, type: Time
  field :updated_at, type: Time
  field :ip_address, type: String
  field :user_agent, type: String

  index(_id: 'hashed')
end
