# frozen_string_literal: true

module Api
  module V1
    module User
      module Im
        class ChannelConversationsController < Api::V1::User::Im::ConversationsController
          def index
            channel_ids = []
            channel_ids += current_user.all_channels_with_credentials(%i[participate_channel_conversation moderate_channel_conversation])
                                       .where(im_conversation_enabled: true)
                                       .pluck(:id)
            channel_ids += Channel.joins(subscription: { plans: :stripe_subscriptions })
                                  .where(
                                    im_conversation_enabled: true,
                                    stripe_subscriptions: { user_id: current_user.id, status: %w[active trialing] },
                                    stripe_plans: { im_channel_conversation: true }
                                  ).pluck(:id)
            channel_ids += current_user.free_subscriptions
                                       .in_action
                                       .with_features(:im_channel_conversation)
                                       .joins(:channel)
                                       .where(channels: { archived_at: nil, im_conversation_enabled: true })
                                       .where.not(channels: { listed_at: nil })
                                       .pluck('channels.id')
            if Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
              channel_ids = Channel.not_archived.listed
                                   .joins('JOIN organizations ON organizations.id = channels.organization_id')
                                   .joins('JOIN users ON users.id = organizations.user_id')
                                   .joins('LEFT JOIN stripe_service_subscriptions ON stripe_service_subscriptions.user_id = users.id')
                                   .where("stripe_service_subscriptions.service_status != 'deactivated' OR organizations.split_revenue_plan = TRUE")
                                   .where(id: channel_ids).pluck(:id)
            else
              channel_ids = Channel.not_archived.listed.where(id: channel_ids).pluck(:id)
            end
            query = ::Im::Conversation.where(conversationable_type: 'Channel', conversationable_id: channel_ids)
            @count = query.count
            @conversations = query.limit(@limit).offset(@offset).preload([{ conversationable: %i[logo cover] }, :last_message])
          end

          private

          def current_ability
            @current_ability ||= AbilityLib::ChannelAbility.new(current_user)
          end
        end
      end
    end
  end
end
