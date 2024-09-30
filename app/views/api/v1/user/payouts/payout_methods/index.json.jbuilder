# frozen_string_literal: true

envelope json do
  json.array! @payout_methods do |payout_method|
    json.partial! 'api/v1/user/payouts/payout_methods/payout_method', payout_method: payout_method
  end
end
