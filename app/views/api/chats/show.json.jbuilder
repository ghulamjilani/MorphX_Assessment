# frozen_string_literal: true

envelope json do
  as = @room.abstract_session
  json.chat do
    json.user_name current_user.public_display_name
    json.user_avatar_url current_user.avatar_url
    json.webrtcservice_channel_id as&.webrtcservice_channel_id
    json.token @jwt_token
  end
end
