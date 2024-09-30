# frozen_string_literal: true

envelope json do
  json.stream_previews do
    json.array! @stream_previews do |stream_preview|
      json.stream_preview do
        json.partial! 'stream_preview', stream_preview: stream_preview
        json.ffmpegservice_account do
          json.partial! 'ffmpegservice_account', ffmpegservice_account: stream_preview.ffmpegservice_account
        end
      end
    end
  end
end
