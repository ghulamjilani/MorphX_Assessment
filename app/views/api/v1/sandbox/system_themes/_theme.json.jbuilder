# frozen_string_literal: true

json.extract! model, :id, :name, :is_default, :custom_css, :updated_at, :created_at
json.system_theme_variables do
  json.array! model.system_theme_variables do |variable|
    json.extract! variable, :id, :name, :property, :value, :group_name, :state, :system_theme_id, :updated_at,
                  :created_at
  end
end
