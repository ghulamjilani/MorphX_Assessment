# frozen_string_literal: true

envelope json do
  json.interactive_access_token do
    json.guests @interactive_access_token.guests
  end
end
