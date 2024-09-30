# frozen_string_literal: true

module Api
  module V1
    module User
      module Im
        class ConversationsController < Api::V1::User::Im::ApplicationController
          def show
            @conversation = ::Im::Conversation.find(params.require(:id))
            @conversationable = @conversation.conversationable
            raise AccessForbiddenError unless can?(:read_im_conversation, @conversationable)
          end

          private

          def current_ability
            @current_ability ||= AbilityLib::ChannelAbility.new(current_user).merge(AbilityLib::SessionAbility.new(current_user_or_guest))
          end
        end
      end
    end
  end
end
