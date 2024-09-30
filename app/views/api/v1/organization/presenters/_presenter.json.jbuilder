# frozen_string_literal: true

json.id                   presenter.id
json.user_id              presenter.user_id
json.created_at           presenter.created_at.utc.to_fs(:rfc3339)
json.updated_at           presenter.updated_at.utc.to_fs(:rfc3339)
json.credit_line_amount   presenter.credit_line_amount
json.featured             presenter.featured
