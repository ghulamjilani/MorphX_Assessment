# frozen_string_literal: true

module Log
  class UserEvent
    include ::Mongoid::Document
    include ::Mongoid::Timestamps::Created
    store_in collection: 'log_user_events'

    field :platform,          type: String
    field :user_id,           type: Integer
    field :event_time,        type: DateTime
    field :user_agent,        type: String
    field :user_ip,           type: String
    field :data,              type: String
    field :page,              type: String
    field :service,           type: String # Interactive/OnlineStreaming/Playback
    field :event_type,        type: String ## Connect, Disconnect, - Interactive Chunk, Rewind - Online, Playback, In, Out, Pause Size?
  end
end
