# frozen_string_literal: true

module KafkaLib
  class Client
    EVENT_USER_TOPIC    = 'user_topic'
    EVENT_SYSTEM_TOPIC  = 'system_topic'
    EVENT_ALL           = [EVENT_USER_TOPIC, EVENT_SYSTEM_TOPIC].freeze

    def self.config
      @config ||= begin
        YAML.load_file("#{Rails.root}/config/kafka.yml")[Rails.env]
      rescue StandardError
        nil
      end
    end

    def self.producer
      @producer ||= Kafka.new(@config['brokers'], client_id: @config['application_name']).async_producer
    end

    def self.send_user(request:, service:, event_type:, data: nil, page: nil, user_id: nil)
      data = {
        platform: 'unite',
        user_id: user_id,
        event_time: Time.now.utc,
        user_agent: request.user_agent,
        user_ip: request.ip,
        service: service,
        event_type: event_type,
        data: data,
        page: page
      }
      _send(data: data, topic: EVENT_USER_TOPIC)
    end

    def self.send_system(data:)
      _send(data: data, topic: EVENT_SYSTEM_TOPIC)
    end

    def self._send(data:, topic:)
      if config.blank?
        # FIXME: uncoment it after deploy on morphx prod
        # Airbrake.notify('Please add kafka config')
        puts 'Please add kafka config'
        return nil
      end
      producer.produce(data.to_json, topic: "#{config['application_name']}-#{topic}")
      producer.deliver_messages
    end

    def self.consumer
      @consumer ||= Kafka.new(config['brokers'],
                              client_id: config['application_name']).consumer(group_id: "consumer-#{config['application_name']}")
    end

    def self.check_events
      EVENT_ALL.each do |event|
        consumer.subscribe("#{config['application_name']}-#{event}")
      end
      consumer.each_message do |message|
        begin
          puts message.topic, message.partition
        rescue StandardError
          nil
        end
        begin
          puts message.offset, message.key, message.value
        rescue StandardError
          nil
        end
      end
    end
  end
end
