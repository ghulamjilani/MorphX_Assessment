# frozen_string_literal: true

json.public_info do
  json.id @room.id
  json.active @room.active?
  json.presenter_id @room.presenter_user_id
  json.presenter_name @room.presenter_user.display_name
  json.abstract_session_type @room.abstract_session_type
  json.abstract_session_id @room.abstract_session_id
end

json.current_user do
  json.id current_user.id
  json.name current_user.display_name
  json.role @role
end

if show_vidyo_credentials?(room: @room, role: @role)
  json.vidyo do
    json.token @room.vidyoio_token
    json.host 'prod.vidyo.io'
    json.resourceId @room.presenter_user_id.to_s
    json.displayName current_user.full_name
  end
end
