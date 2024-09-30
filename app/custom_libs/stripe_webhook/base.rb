# frozen_string_literal: true

module StripeWebhook
  class Base
    @event_type = nil

    def self.event_type
      raise "fix event type for #{self.class}" if @event_type.nil?

      @event_type
    end

    def initialize(event:)
      @event = event
      @logger = Logger.new "#{Rails.root}/log/debug_stripe_webhook.#{Rails.env}.log"
    end

    def perform
      raise 'stub'
    end
  end
end
