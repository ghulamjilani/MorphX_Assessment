# frozen_string_literal: true

envelope json do
  json.stop_at @stop_at&.utc&.to_fs(:rfc3339)
  json.ffmpegservice_account do
    json.partial! 'ffmpegservice_account', ffmpegservice_account: @ffmpegservice_account
  end
end
