# frozen_string_literal: true

json.id                     record.id
json.model_type             record.model_type
json.model_id               record.model_id
json.relation_type          record.relation_type
json.byte_size              record.byte_size
json.created_at             record.created_at.utc.to_fs(:rfc3339)
json.updated_at             record.updated_at.utc.to_fs(:rfc3339)
