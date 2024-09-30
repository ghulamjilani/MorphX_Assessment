# frozen_string_literal: true

envelope json do
  json.recordings do
    json.array! @recordings do |recording|
      json.recording do
        json.partial! 'recording_short', model: recording

        json.organizer do
          org = recording.organizer
          json.url                  org.relative_path
          json.public_display_name  org.public_display_name
        end
      end
    end
  end
end
