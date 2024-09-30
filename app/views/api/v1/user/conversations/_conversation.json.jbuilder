# frozen_string_literal: true

json.id                   conversation.id
json.updated_at           conversation.updated_at.to_s(:rfc3339)
json.created_at           conversation.created_at.to_s(:rfc3339)
