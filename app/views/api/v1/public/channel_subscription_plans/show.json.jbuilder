# frozen_string_literal: true

envelope json, (@status || 200), (@plan.pretty_errors if @plan.errors.present?) do
  json.plan do
    json.partial! 'plan', model: @plan
  end
end
