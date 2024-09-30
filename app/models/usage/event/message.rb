# frozen_string_literal: true

module Usage
  class Event
    class Message
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ModelConcerns::HasErrors

      class << self
        def topic
          raise NotInheritedError
        end
      end

      attribute :channel_id, :integer
      attribute :client_type, :string
      attribute :data, :string
      attribute :embed_domain, :string
      attribute :event_time, :string
      attribute :event_type, :string
      attribute :event_value, :string
      attribute :host_id, :integer
      attribute :ip, :string
      attribute :model_id, :integer
      attribute :model_type, :string
      attribute :organization_id, :integer
      # attribute :platform, :string
      attribute :user_agent, :string
      # attribute :user_id, :integer
      attribute :video_resolution, :string
      attribute :visitor_id, :string

      def topic
        raise NotInheritedError
      end

      delegate :to_json, to: :attributes
    end
  end
end
