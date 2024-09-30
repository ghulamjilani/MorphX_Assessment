# frozen_string_literal: true

envelope json, (@status || 200), (@stream_preview.pretty_errors if @stream_preview.errors.present?) do
  json.stream_preview do
    json.partial! 'stream_preview', stream_preview: @stream_preview
    json.ffmpegservice_account do
      json.partial! 'ffmpegservice_account', ffmpegservice_account: @stream_preview.ffmpegservice_account
    end
  end
end
