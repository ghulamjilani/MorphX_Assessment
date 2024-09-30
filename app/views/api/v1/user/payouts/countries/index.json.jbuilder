# frozen_string_literal: true

envelope json do
  json.array! @countries do |code, name|
    json.code code
    json.name name
  end
end
