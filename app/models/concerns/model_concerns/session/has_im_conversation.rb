# frozen_string_literal: true

module ModelConcerns
  module Session
    module HasImConversation
      extend ActiveSupport::Concern

      included do
        def im_conversation_closed?
          return true unless allow_chat?
          return true unless started?

          finished?
        end
      end
    end
  end
end
