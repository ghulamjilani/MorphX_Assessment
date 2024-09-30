# frozen_string_literal: true

module AbilityLib
  module Im
    class MessageAbility < AbilityLib::Im::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          moderate: [::Im::Message]
        }
      end

      def load_permissions
        return unless user_or_guest.persisted?

        can :edit, ::Im::Message do |message|
          message.conversation_participant.abstract_user == user_or_guest
        end

        return unless user.persisted?

        can :moderate, ::Im::Message do |message|
          case message.conversationable.class.name
          when 'Channel'
            user.has_channel_credential?(message.conversationable, :moderate_channel_conversation)
          when 'Session'
            user.has_channel_credential?(message.conversationable.channel, :moderate_session_conversation)
          end
        end
      end
    end
  end
end
