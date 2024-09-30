# frozen_string_literal: true

json.extract! notification, :id, :subject, :body
json.is_read              notification.is_read?(current_user)
json.updated_at           notification.updated_at.utc.to_fs(:rfc3339)
json.created_at           notification.created_at.utc.to_fs(:rfc3339)
