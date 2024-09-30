# frozen_string_literal: true

module ImWebrtcservice
  module Events
    @registered_handlers = [Handlers::OnMessageSentHandler].freeze

    class << self
      attr_reader :registered_handlers

      def handle(params:)
        find_handler(params[:EventType])&.process(params: params) || :handler_not_implemented
      end

      private

      def find_handler(event_type)
        registered_handlers.find { |handler| handler.event_type == event_type }
      end
    end
  end
end
