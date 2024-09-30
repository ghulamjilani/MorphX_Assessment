# frozen_string_literal: true

envelope json do
  json.ban_reasons do
    json.array! @ban_reasons do |ban_reason|
      json.partial! 'ban_reason', ban_reason: ban_reason
    end
  end
end
