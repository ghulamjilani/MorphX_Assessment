# frozen_string_literal: true

json.id connect_account.id
json.business_profile stripe_item.business_profile
json.business_type stripe_item.business_type
json.capabilities stripe_item.capabilities
json.company stripe_item.company
json.country stripe_item.country
json.default_currency stripe_item.default_currency
json.details_submitted stripe_item.details_submitted
json.future_requirements stripe_item.future_requirements
json.individual stripe_item.individual
json.payouts_enabled stripe_item.payouts_enabled
json.requirements stripe_item.requirements
json.type stripe_item.type

json.bank_account do
  json.partial! 'api/v1/user/payouts/payout_methods/connect_bank_account', bank_account: connect_account.bank_accounts.first
end
