# frozen_string_literal: true

envelope json, (@status || 200), (@ffmpegservice_account.pretty_errors if @ffmpegservice_account.errors.present?) do
  json.ffmpegservice_account do
    json.partial! 'ffmpegservice_account', ffmpegservice_account: @ffmpegservice_account
  end
  if @ffmpegservice_account.studio_room
    json.studio_room do
      json.partial! 'api/v1/user/studio_rooms/studio_room', studio_room: @ffmpegservice_account.studio_room
    end
  end
end
