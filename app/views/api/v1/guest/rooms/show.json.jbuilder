# frozen_string_literal: true

envelope json, (@status || 200), (@room.pretty_errors if @room.errors.present?) do
  json.room do
    json.partial! 'room', room: @room

    json.no_presenter_stop_scheduled_at @room.no_presenter_stop_scheduled_at

    json.presenter_user do
      json.extract! @room.presenter_user, :id, :public_display_name, :relative_path, :avatar_url
    end

    if @session
      json.abstract_session do
        json.partial! 'api/v1/public/sessions/session', model: @session
      end
    end

    json.channel do
      json.extract! @channel, :id, :title, :description,
                    :organization_id, :category_id,
                    :relative_path, :short_url, :logo_url
      json.cover_url @channel.image_url
    end

    json.service_token @service_token

    json.room_members do
      json.array! @room.room_members do |room_member|
        json.room_member do
          json.partial! 'api/v1/user/room_members/room_member', room_member: room_member
          json.guest room_member.guest?

          if room_member.user
            json.user do
              json.partial! 'api/v1/user/users/user_short', user: room_member.abstract_user
            end
          end

          json.abstract_user do
            json.partial! 'api/v1/user/room_members/abstract_user', abstract_user: room_member.abstract_user
            json.type room_member.abstract_user_type
          end
        end
      end
    end

    json.current_room_member do
      json.partial! 'api/v1/user/room_members/room_member', room_member: @current_room_member
      json.guest @current_room_member.guest?

      json.abstract_user do
        json.partial! 'api/v1/user/room_members/abstract_user', abstract_user: @current_room_member.abstract_user
        json.type @current_room_member.abstract_user_type
      end
    end

    json.interactive_access_tokens do
      json.array! @interactive_access_tokens do |interactive_access_token|
        json.partial! 'api/v1/public/interactive_access_tokens/interactive_access_token',
                      interactive_access_token: interactive_access_token
      end
    end

    json.role @role
  end
end
