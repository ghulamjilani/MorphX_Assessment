# frozen_string_literal: true

class Api::ChatsController < Api::ApplicationController
  include ActionView::Rendering

  respond_to :json

  def show
    @room = Room.upcoming.not_cancelled.find(params[:id])
    if current_user
      grant = Webrtcservice::JWT::AccessToken::ChatGrant.new
      grant.service_sid = ENV['webrtcservice_CHAT_SID']

      token = Webrtcservice::JWT::AccessToken.new(
        ENV['webrtcservice_ACCOUNT_SID'],
        ENV['webrtcservice_CHAT_API_KEY'],
        ENV['webrtcservice_CHAT_API_SECRET'],
        [grant],
        identity: current_user.id
      )
      @jwt_token = token.to_jwt
    end
  end

  def switch
    room = Room.where(presenter_user_id: current_user.id).find(params[:room_id])
    session = room.abstract_session
    @allow = false
    if session.is_a?(Session)
      if session.allow_chat?
        room.disable_chat
      else
        room.enable_chat
        @allow = true
      end
    end
  end
end
