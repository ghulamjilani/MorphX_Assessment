# frozen_string_literal: true

json.extract! plan, :id, :active, :stripe_id, :trial_period_days, :plan_package_id
json.name plan.plan_package&.name
json.nickname plan.nickname
json.amount plan.amount
json.currency plan.currency
json.interval plan.interval
json.interval_count plan.interval_count

json.monthly_amount plan.monthly_amount.round
json.annual_amount plan.annual_amount.round

json.formatted_price plan.formatted_price
json.formatted_interval plan.formatted_interval
