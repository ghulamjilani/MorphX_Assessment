# frozen_string_literal: true

module Cable
  class CustomRedis
    class << self
      def client=(redis)
        @client = Redis::Namespace.new(:custom_cable_, redis: redis)
      end

      attr_reader :client
    end
  end
end
