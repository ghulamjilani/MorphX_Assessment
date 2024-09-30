# frozen_string_literal: true

module Webrtcservice
  class BansController < ApplicationController
    before_action :authenticate_user!
    skip_before_action :gon_init
    skip_before_action :check_if_has_needed_cookie
    skip_before_action :extract_refc_from_url_into_cookie
    skip_before_action :check_if_referral_user
    skip_after_action :prepare_unobtrusive_flash
    skip_before_action :fetch_latest_notifications
    skip_before_action :fetch_upcoming_sessions_for_user
    skip_before_action :store_current_location

    def create
      chat_ban = ChatBan.new(user_id: current_user.id)
      chat_channel = ChatChannel.find_by!(webrtcservice_id: params[:channel_id])
      session = Session.find(chat_channel.session_id)
      if current_user == session&.presenter&.user
        if params[:author_type] == 'ChatMember'
          member = ChatMember.find(params[:author_id])
          if member.present?
            chat_ban.channel_id = session.channel_id
            chat_ban.banned_id = member.id.to_s
            chat_ban.banned_type = 'ChatMember'
            chat_ban.ip_address = member.ip_address
            chat_ban.user_agent = member.user_agent
            chat_ban.save
            chat_channel.chat_messages.where(user_id: chat_ban.banned_id, user_type: chat_ban.banned_type).destroy_all

            client = Webrtcservice::REST::Client.new(ENV['webrtcservice_ACCOUNT_SID'], ENV['webrtcservice_AUTH_TOKEN'])
            webrtcservice_messages = client.chat.services(ENV['webrtcservice_CHAT_SID']).channels(chat_channel.webrtcservice_id).messages.list
            webrtcservice_messages.each do |msg|
              if msg.from == member.id.to_s
                msg.delete
              end
            end

            SessionsChannel.broadcast 'chat_member_banned', {
              user_id: chat_ban.banned_id,
              user_type: chat_ban.banned_type,
              session_id: session.id,
              channel_id: params[:channel_id]
            }
          end
        else
          User.find(params[:author_id])
        end
      end
      render json: {}, status: 200
    end
  end
end
