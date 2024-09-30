# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    after_subscribe :subscribers_incr
    after_unsubscribe :subscribers_decr
    after_subscribe :kafka_event_subscribe
    after_unsubscribe :kafka_event_unsubscribe

    EVENTS = {}.freeze

    class << self
      def client
        @client ||= Cable::CustomRedis.client = Redis.new(url: ENV['SESSION_REDIS_URL'])
      end

      def pubsub
        @pubsub ||= ActionCable.server.pubsub
      end

      def broadcast(event, data = {})
        validate_event(event)
        ActionCable.server.broadcast name.to_s.underscore, { event: event, data: data }
      end

      def broadcast_to(model, message)
        validate_event(message.with_indifferent_access[:event]) if message.is_a?(Hash) && message.with_indifferent_access.has_key?(:event)
        super(model, message)
      end

      def channel_prefix
        "#{name.to_s.underscore}:"
      end

      def channel_with_prefix
        pubsub.send(:channel_with_prefix, channel_name)
      end

      def channels
        pubsub.send(:redis_connection).pubsub('channels', "#{channel_with_prefix}:*")
      end

      def subscriptions
        channels.map do |channel|
          Base64.decode64(channel.match(/^#{Regexp.escape(channel_with_prefix)}:(.*)$/)[1])
        end
      end

      def gid_uri_pattern
        %r{^gid://.*/([a-zA-Z]+/\d+)$}
      end

      def active_subscriptions
        chat_ids = subscriptions.map do |subscription|
          subscription.match(gid_uri_pattern)
        end.compact.map { |match| match[1] }
      end

      def subscribers_count_prefix
        "count_#{channel_prefix}"
      end

      def active_channels_keys
        client.keys("#{subscribers_count_prefix}*")
      end

      def active_listeners_uids
        connections = client.pubsub('channels', "#{channel_prefix}*").map { |c| c.gsub(channel_prefix, '') }
        listeners = {}
        connections.each do |connection|
          connection = connection.split(':')
          next if connection.size != 2

          object_id, listener_uid = connection
          listeners[object_id] = [] unless listeners.key?(object_id)
          listeners[object_id].push(listener_uid)
        end

        listeners
      end

      def active_users_ids
        users_ids = {}
        active_listeners_uids.each do |object_id, listeners_uids|
          ids = listeners_uids.reject { |uid| uid.starts_with? '_' }
          users_ids[object_id] = ids if ids.present?
        end
        users_ids
      end

      def subscribers_count(prefix)
        client.get(prefix)
      end

      def validate_event(event)
        return if self::EVENTS.keys.map(&:to_sym).include?(event.to_sym)

        raise "#{event} in not listed in #{name} channel" if Rails.env.test?

        Airbrake.notify('Unlisted actioncable channel event', parameters: { channel: name.to_s, event: event })
      end
    end

    def channel_prefix
      "#{self.class.channel_prefix}#{params[:data]}:"
    end

    def subscribers_count_key
      "#{self.class.subscribers_count_prefix}#{params[:data]}"
    end

    def active_listeners_uids
      self.class.client.pubsub('channels', "#{channel_prefix}*").map { |c| c.gsub(channel_prefix, '') }
    end

    def active_users_ids
      active_listeners_uids.reject { |id| id.to_s.starts_with? '_' }.map(&:to_i)
    end

    def subscribers_incr
      self.class.client.incr(subscribers_count_key).to_i
    end

    def subscribers_decr
      if subscribers_count.positive?
        self.class.client.decr(subscribers_count_key).to_i
      else
        0
      end
    end

    def subscribers_count
      self.class.client.get(subscribers_count_key).to_i
    end

    def kafka_event_subscribe
      KafkaLib::Client.send_user(request: connection.send(:request), service: self.class.name,
                                 event_type: 'subscribe', data: params, user_id: current_user&.id)
    end

    def kafka_event_unsubscribe
      KafkaLib::Client.send_user(request: connection.send(:request), service: self.class.name,
                                 event_type: 'unsubscribe', data: params, user_id: current_user&.id)
    end

    private

    def debug_logger(name, data = {})
      @custom_logger ||= Logger.new Rails.root.join("log/#{self.class.to_s.underscore.tr('/', '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log")
      @custom_logger.level = Logger::DEBUG
      @custom_logger.debug("#{name} | #{data}")
    rescue StandardError => e
      Airbrake.notify(e)
    end
  end
end
