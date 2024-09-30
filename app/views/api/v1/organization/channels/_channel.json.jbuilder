# frozen_string_literal: true

json.id               channel.id
json.organization_id  channel.organization_id
json.status           channel.status
json.title            channel.title
json.description      channel.description
json.shares_count     channel.shares_count
json.created_at       channel.created_at.utc.to_fs(:rfc3339)
json.updated_at       channel.updated_at.utc.to_fs(:rfc3339)
