# frozen_string_literal: true

envelope json, 201 do
  json.errors user.pretty_errors
end
