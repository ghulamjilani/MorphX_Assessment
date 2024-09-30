# frozen_string_literal: true

json.extract! message, :id, :body, :subject, :sender_id
json.updated_at           message.updated_at.utc.to_fs(:rfc3339)
json.created_at           message.created_at.utc.to_fs(:rfc3339)
