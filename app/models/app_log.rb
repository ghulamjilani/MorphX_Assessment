# frozen_string_literal: true

class AppLog
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: 'app_logs'

  field :browser, type: String
  field :ip, type: String
  field :call_id, type: String
  field :platform, type: String
  field :log, type: String

  index(_id: 'hashed')
end
