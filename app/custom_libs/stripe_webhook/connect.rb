# frozen_string_literal: true

Dir["#{Rails.root}/app/custom_libs/stripe_webhook/connect_events/*.rb"].each { |file| require_dependency file }
module StripeWebhook
  module Connect
    def self.handle(params:)
      event = Stripe::Event.retrieve(params['id'], stripe_account: params['account'])
      event_classes = StripeWebhook::Base.subclasses.select do |klass|
                        klass.to_s.include?('ConnectEvents')
                      end.find_all do |handler|
        handler.event_type == event.type
      end
      if event_classes.blank?
        :handler_not_implemented
      else
        event_classes.each { |klass| klass.new(event: event).perform }
      end
    end
  end
end
