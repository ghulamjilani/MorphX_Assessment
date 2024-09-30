# frozen_string_literal: true

json.extract! stream_preview, :id, :organization_id, :user_id, :ffmpegservice_account_id
json.end_at     stream_preview.end_at&.utc&.to_fs(:rfc3339)
json.created_at stream_preview.created_at.utc.to_fs(:rfc3339)
json.updated_at stream_preview.updated_at.utc.to_fs(:rfc3339)
json.stopped_at nil if stream_preview.stopped_at.blank?
json.stopped_at stream_preview.stopped_at&.utc&.to_fs(:rfc3339) if stream_preview.stopped_at.present?
