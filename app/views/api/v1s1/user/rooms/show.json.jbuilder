# frozen_string_literal: true

envelope json, (@status || 200), (@room.pretty_errors if @room.errors.present?) do
  json.room do
    json.partial! 'api/v1/user/rooms/room', room: @room
  end

  json.presenter_user do
    json.partial! 'api/v1/user/users/user_short', user: @room.presenter_user
  end

  if @abstract_session
    json.abstract_session do
      json.partial! 'api/v1/user/sessions/session', session: @abstract_session

      json.current_list_id @abstract_session.lists.first&.id
    end
  end

  if @channel
    json.channel do
      json.partial! 'api/v1/user/channels/channel', channel: @channel
    end
  end

  json.room_members do
    json.array! @room.room_members do |room_member|
      json.room_member do
        json.partial! 'api/v1/user/room_members/room_member', room_member: room_member
        json.guest room_member.guest?

        if room_member.user
          json.user do
            json.partial! 'api/v1/user/users/user_short', user: room_member.user
          end
        end
      end
    end
  end

  if @current_room_member
    json.current_room_member do
      json.partial! 'api/v1/user/room_members/room_member', room_member: @current_room_member
      json.guest @current_room_member.guest?

      json.abstract_user do
        json.partial! 'api/v1/user/room_members/abstract_user', abstract_user: @current_room_member.abstract_user
        json.type @current_room_member.abstract_user_type
      end

      if @current_room_member.user
        json.user do
          json.partial! 'api/v1/user/users/user_short', user: @current_room_member.user
        end
      end
    end
  end

  if @service_token
    json.service_token @service_token
  end

  if @interactive_access_tokens
    json.interactive_access_tokens do
      json.array! @interactive_access_tokens do |interactive_access_token|
        json.partial! 'api/v1/user/interactive_access_tokens/interactive_access_token',
                      interactive_access_token: interactive_access_token
      end
    end
  end

  if @ffmpegservice_account.present?
    json.ffmpegservice_account do
      json.partial! 'api/v1/user/ffmpegservice_accounts/ffmpegservice_account', ffmpegservice_account: @ffmpegservice_account
    end
  end

  json.role @role

  json.hls_url @can_see_livestream ? @abstract_session.ffmpegservice_account&.hls_url : nil
end
