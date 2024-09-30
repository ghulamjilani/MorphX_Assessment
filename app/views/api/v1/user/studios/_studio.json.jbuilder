# frozen_string_literal: true

json.id                        studio.id
json.organization_id           studio.organization_id
json.name                      studio.name
json.description               studio.description
json.address                   studio.address
json.phone                     studio.phone
json.created_at                studio.created_at.utc.to_fs(:rfc3339)
json.updated_at                studio.updated_at.utc.to_fs(:rfc3339)
