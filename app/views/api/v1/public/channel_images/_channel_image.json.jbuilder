# frozen_string_literal: true

json.id                                   channel_image.id
json.featured                             channel_image.featured
json.created_at                           channel_image.created_at.utc.to_fs(:rfc3339)
json.updated_at                           channel_image.updated_at.utc.to_fs(:rfc3339)
