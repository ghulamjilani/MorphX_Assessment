# frozen_string_literal: true

envelope json do
  json.ffmpegservice_accounts do
    json.array! @ffmpegservice_accounts do |ffmpegservice_account|
      json.ffmpegservice_account do
        json.partial! 'ffmpegservice_account', ffmpegservice_account: ffmpegservice_account
      end
      if ffmpegservice_account.studio_room
        json.studio_room do
          json.partial! 'api/v1/user/studio_rooms/studio_room', studio_room: ffmpegservice_account.studio_room
        end
      end
    end
  end
end
