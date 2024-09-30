# frozen_string_literal: true

envelope json, (@status || 200), (@plan_package.pretty_errors if @plan_package.errors.present?) do
  json.partial! 'plan_package', plan_package: @plan_package
end
