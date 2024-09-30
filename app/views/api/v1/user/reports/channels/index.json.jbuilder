# frozen_string_literal: true

envelope json do
  json.array! @channels do |channel|
    json.id channel.id
    json.title channel.title
  end
end
