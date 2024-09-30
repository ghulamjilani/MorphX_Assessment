# frozen_string_literal: true

json.id                                   channel_image.id
json.name                                 channel_image.name
json.description_in_markdown_format       channel_image.description_in_markdown_format
json.featured                             channel_image.featured
json.created_at                           channel_image.created_at.utc.to_fs(:rfc3339)
json.updated_at                           channel_image.updated_at.utc.to_fs(:rfc3339)
