# frozen_string_literal: true

json.id                   activity.id
json.key                  activity.key
json.parameters           activity.parameters
json.created_at           activity.created_at.utc.to_fs(:rfc3339)
json.updated_at           activity.updated_at.utc.to_fs(:rfc3339)
