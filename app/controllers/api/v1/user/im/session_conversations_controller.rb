# frozen_string_literal: true

module Api
  module V1
    module User
      module Im
        class SessionConversationsController < Api::V1::User::Im::ConversationsController
          skip_user_authorization
          optional_authorization

          def show
            @conversationable = ::Session.find(params.require(:session_id))
            raise ActiveRecord::RecordNotFound unless @conversationable.allow_chat?

            @conversation = @conversationable.im_conversation || @conversationable.create_im_conversation
          end

          private

          def current_ability
            @current_ability ||= AbilityLib::SessionAbility.new(current_user_or_guest)
          end
        end
      end
    end
  end
end
