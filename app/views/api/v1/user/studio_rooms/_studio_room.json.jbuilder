# frozen_string_literal: true

json.id                        studio_room.id
json.studio_id                 studio_room.studio_id
json.name                      studio_room.name
json.description               studio_room.description
json.created_at                studio_room.created_at.utc.to_fs(:rfc3339)
json.updated_at                studio_room.updated_at.utc.to_fs(:rfc3339)
