# frozen_string_literal: true

json.id                                   channel_category.id
json.name                                 channel_category.name
json.description_in_markdown_format       channel_category.description_in_markdown_format
json.featured                             channel_category.featured
json.created_at                           channel_category.created_at.utc.to_fs(:rfc3339)
json.updated_at                           channel_category.updated_at.utc.to_fs(:rfc3339)
