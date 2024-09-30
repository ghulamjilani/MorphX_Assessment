# frozen_string_literal: true

module Api
  module V1
    module User
      module Im
        class MessagesController < Api::V1::User::Im::ApplicationController
          skip_before_action :authorization, if: -> { action_name == 'index' && request.headers['Authorization'].blank? }
          skip_before_action :authorization_only_for_user
          before_action :authorization_only_for_user_or_guest, except: %i[index]

          def index
            raise AccessForbiddenError unless can?(:read_im_conversation, conversation.conversationable)

            query = conversation.messages.not_deleted

            if params[:created_at_from].present? && params[:created_at_to].present?
              query = query.where(created_at: params[:created_at_from]..params[:created_at_to])
            elsif params[:created_at_from].present?
              query = query.where('created_at >= ?', params[:created_at_from])
            elsif params[:created_at_to].present?
              query = query.where('created_at <= ?', params[:created_at_to])
            end

            query = if params[:order].to_s.eql?('asc')
                      query.order(created_at: :asc)
                    else
                      query.order(created_at: :desc)
                    end

            @count = query.count
            @messages = query.limit(@limit).offset(@offset).preload(conversation_participant: :abstract_user)
          end

          def create
            raise AccessForbiddenError unless can?(:create_im_message, conversation.conversationable)

            conversation_participant = conversation.conversation_participants.find_or_create_by!(abstract_user: current_user_or_guest)

            @message = ::Im::Message.create!(
              conversation: conversation,
              conversation_participant: conversation_participant,
              body: message_params[:body]
            )
            render :show
          end

          def update
            raise AccessForbiddenError unless can?(:edit, message)

            message.update!(message_params.merge({ modified_at: Time.now.utc }))
            @message.reload
            render :show
          end

          def destroy
            raise AccessForbiddenError unless can?(:edit, message) || can?(:moderate_im_conversation, conversation.conversationable)

            message.update!(deleted_at: Time.now.utc)
            @message.reload
            render :show
          end

          private

          def message
            @message ||= ::Im::Message.not_deleted.find(params[:id])
            raise(ActiveRecord::RecordNotFound, I18n.t('controllers.api.v1.user.im.messages.errors.not_found')) unless @message

            @message
          end

          def message_params
            params.require(:message).permit(:body)
          end

          def conversation
            @conversation ||= ::Im::Conversation.find(params[:conversation_id])
          end

          def current_ability
            @current_ability ||= AbilityLib::Im::MessageAbility.new(current_user_or_guest)
                                                               .merge(AbilityLib::ChannelAbility.new(current_user))
                                                               .merge(AbilityLib::SessionAbility.new(current_user_or_guest))
          end
        end
      end
    end
  end
end
