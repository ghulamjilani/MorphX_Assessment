# frozen_string_literal: true

json.extract! interactive_access_token, :id, :session_id, :individual, :guests, :token
json.title                              interactive_access_token.title
json.absolute_url                       interactive_access_token.absolute_url
json.created_at                         interactive_access_token.created_at.utc.to_fs(:rfc3339)
json.updated_at                         interactive_access_token.updated_at.utc.to_fs(:rfc3339)
