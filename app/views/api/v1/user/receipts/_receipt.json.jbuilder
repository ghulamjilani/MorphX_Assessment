# frozen_string_literal: true

json.extract! receipt, :id, :mailbox_type, :is_read, :trashed, :deleted
json.updated_at           receipt.updated_at.utc.to_fs(:rfc3339)
json.created_at           receipt.created_at.utc.to_fs(:rfc3339)
