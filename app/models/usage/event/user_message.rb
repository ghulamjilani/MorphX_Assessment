# frozen_string_literal: true

module Usage
  class Event
    class UserMessage < ::Usage::Event::Message
      validates :model_id, presence: true
      validates :model_type, presence: true

      def topic
        "#{::Usage.config[:platform].underscore}-#{model_type.underscore.tr('/', '-')}"
      end
    end
  end
end
