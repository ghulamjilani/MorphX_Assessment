# frozen_string_literal: true

json.id payout_method.id
json.created_at payout_method.created_at.utc.to_fs(:rfc3339)
json.business_type payout_method.business_type
json.country payout_method.country
json.status payout_method.status
json.is_default payout_method.is_default
json.provider payout_method.provider

if payout_method.connect_account.present?
  json.connect_account do
    json.partial! 'api/v1/user/payouts/payout_methods/connect_account', connect_account: payout_method.connect_account, stripe_item: payout_method.connect_account.stripe_item
  end
end
