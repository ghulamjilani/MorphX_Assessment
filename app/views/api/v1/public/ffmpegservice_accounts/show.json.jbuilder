# frozen_string_literal: true

envelope json, (@status || 200), @errors do
  json.ffmpegservice_account do
    json.partial! 'ffmpegservice_account', ffmpegservice_account: @ffmpegservice_account
  end
end
