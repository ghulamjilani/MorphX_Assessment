# frozen_string_literal: true

envelope json, (@status || 200), (@plan.pretty_errors if @plan.errors.present?) do
  json.partial! 'plan', plan: @plan

  json.money_currency do
    json.partial! 'api/v1/public/money/currencies/currency', currency: @plan.money_currency
  end
end
