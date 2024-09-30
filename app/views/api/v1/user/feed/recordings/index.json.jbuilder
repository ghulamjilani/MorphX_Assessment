# frozen_string_literal: true

envelope json do
  json.recordings_type @recordings_type
  json.recordings do
    json.array! @recordings do |recording|
      json.partial! '/api/v1/user/recordings/index_item', recording: recording
      json.total_views_count recording.views_count
      json.relative_path recording.relative_path

      json.organization do
        json.partial! '/api/v1/user/organizations/organization_short', organization: recording.organization
      end
    end
  end
end
