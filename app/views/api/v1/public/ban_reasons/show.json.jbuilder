# frozen_string_literal: true

envelope json do
  json.ban_reason do
    json.partial! 'ban_reason', ban_reason: @ban_reason
  end
end
