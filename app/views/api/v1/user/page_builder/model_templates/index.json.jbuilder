# frozen_string_literal: true

envelope json do
  json.model_templates do
    json.array! @model_templates do |model_template|
      json.partial! 'model_template', model_template: model_template
    end
  end
end
