# frozen_string_literal: true

envelope json do
  json.array! @sessions do |session|
    json.partial! 'session', session: session
  end
end
