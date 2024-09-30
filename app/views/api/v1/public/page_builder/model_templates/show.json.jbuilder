# frozen_string_literal: true

json.cache! "#{@template_cache_key}/#{@status || 200}", skip_digest: true do
  envelope json, (@status || 200), (model_template.pretty_errors if model_template.errors.present?) do
    json.model_template do
      json.partial! 'model_template', model_template: model_template
    end
  end
end
