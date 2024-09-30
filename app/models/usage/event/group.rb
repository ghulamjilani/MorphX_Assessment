# frozen_string_literal: true

module Usage
  class Event
    class Group
      include ::Mongoid::Document
      include ::Mongoid::Timestamps
      include ModelConcerns::Mongoid::HasColumnNames

      store_in collection: 'events_groups'

      field :channel_id,            type: String
      field :organization_id,       type: String
      field :model_type,            type: String
      field :model_id,              type: String
      field :event_type,            type: String
      field :start_at,              type: DateTime
      field :end_at,                type: DateTime
      field :value,                 type: Integer

      has_many :events_group_users, class_name: '::Usage::Event::GroupUser', inverse_of: :events_group, dependent: :destroy

      index({ channel_id: 1, organization_id: 1, model_type: 1, model_id: 1, event_type: 1, start_at: 1, end_at: 1 }, { unique: true, name: 'group_uniq_index' })

      def model
        @model ||= model_type.classify.constantize.find(model_id)
      rescue StandardError
        nil
      end

      def organization
        @organization ||= lambda do
          return Organization.find(organization_id) if organization_id.present?

          model&.organization
        end.call
      rescue StandardError
        nil
      end

      def channel
        @channel ||= lambda do
          return Channel.find(channel_id) if channel_id.present?

          model&.channel
        end.call
      rescue StandardError
        nil
      end
    end
  end
end
