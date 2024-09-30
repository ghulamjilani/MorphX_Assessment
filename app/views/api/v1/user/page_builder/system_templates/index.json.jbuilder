# frozen_string_literal: true

envelope json do
  json.system_templates do
    json.array! @system_templates do |system_template|
      json.partial! 'system_template', system_template: system_template
    end
  end
end
