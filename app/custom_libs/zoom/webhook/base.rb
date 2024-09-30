# frozen_string_literal: true

module Zoom::Webhook
  class Base
    @event_type = nil

    def self.event_type
      raise "fix event type for #{self.class}" if @event_type.nil?

      @event_type
    end

    def initialize(event:)
      @event = event
    end

    def perform
      raise 'stub'
    end
  end
end
