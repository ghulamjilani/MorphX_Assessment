# frozen_string_literal: true

at_exit do
  KafkaLib::Client.producer.shutdown
rescue StandardError
  nil
end
