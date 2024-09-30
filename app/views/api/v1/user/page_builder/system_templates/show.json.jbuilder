# frozen_string_literal: true

envelope json, (@status || 200), (@system_template.pretty_errors if @system_template.errors.present?) do
  json.system_template do
    json.partial! 'system_template', system_template: @system_template
  end
end
