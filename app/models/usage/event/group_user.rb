# frozen_string_literal: true

module Usage
  class Event
    class GroupUser
      include ::Mongoid::Document
      include ::Mongoid::Timestamps
      include ModelConcerns::Mongoid::HasColumnNames

      store_in collection: 'events_group_users'

      field :client_type,       type: String
      field :embed_domain,      type: String
      field :ip,                type: String
      field :last_resolution,   type: String
      field :user_agent,        type: String
      field :user_id,           type: String
      field :value,             type: Integer
      field :visitor_id,        type: String

      belongs_to :events_group, class_name: '::Usage::Event::Group'

      delegate :model_id, :model_type, :event_type, to: :events_group

      index({ events_group_id: 1, user_id: 1, ip: 1, user_agent: 1, embed_domain: 1, client_type: 1 }, { unique: true, name: 'group_user_uniq_index' })
    end
  end
end
