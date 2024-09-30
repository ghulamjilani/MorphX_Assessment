# frozen_string_literal: true

json.cache! "#{@template_cache_key}#{@status || 200}", skip_digest: true do
  envelope json, (@status || 200), (system_template.pretty_errors if system_template.errors.present?) do
    json.system_template do
      json.partial! 'system_template', system_template: system_template
    end
  end
end
