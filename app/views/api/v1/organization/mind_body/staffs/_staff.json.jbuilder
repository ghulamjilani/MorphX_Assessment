# frozen_string_literal: true

json.id                   staff.id
json.user_id              staff.user_id
json.remote_id            staff.remote_id
json.email                staff.email
json.name                 staff.name
json.first_name           staff.first_name
json.last_name            staff.last_name
json.is_male              staff.is_male
json.bio                  staff.bio
json.address              staff.address
json.city                 staff.city
json.state                staff.state
json.country              staff.country
json.postal_code          staff.postal_code
json.mobile_phone         staff.mobile_phone
json.work_phone           staff.work_phone
json.created_at           staff.created_at.utc.to_fs(:rfc3339)
json.updated_at           staff.updated_at.utc.to_fs(:rfc3339)
