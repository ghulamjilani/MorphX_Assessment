# frozen_string_literal: true

envelope json do
  json.recordings_type @recordings_type
  json.recordings do
    json.array! @recordings do |recording|
      json.partial! 'index_item', recording: recording
    end
  end
end
