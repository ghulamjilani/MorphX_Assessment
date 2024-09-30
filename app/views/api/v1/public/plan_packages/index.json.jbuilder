# frozen_string_literal: true

envelope json do
  json.array! @plan_packages do |plan_package|
    json.partial! 'plan_package', plan_package: plan_package
  end
end
