# frozen_string_literal: true

json.extract! theme, :id, :name, :is_default, :custom_css
json.variables do
  json.array! theme.system_theme_variables do |variable|
    json.extract! variable, :id, :name, :group_name, :property, :value, :state
  end
end
