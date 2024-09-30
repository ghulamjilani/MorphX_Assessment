# frozen_string_literal: true

Dir["#{Rails.root}/app/custom_libs/stripe_webhook/general_events/*.rb"].each { |file| require_dependency file }
module StripeWebhook
  module General
    def self.handle(params:)
      event = Stripe::Event.retrieve(params['id'])
      event_classes = StripeWebhook::Base.subclasses.select do |klass|
                        klass.to_s.include?('GeneralEvents')
                      end.find_all do |handler|
        handler.event_type == event.type
      end
      if event_classes.blank?
        :handler_not_implemented
      else
        begin
          event_classes.each { |klass| klass.new(event: event).perform }
        rescue StandardError => e
          return false
        end
      end
    end
  end
end
