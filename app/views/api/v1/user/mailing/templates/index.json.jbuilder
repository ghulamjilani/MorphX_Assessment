# frozen_string_literal: true

json.templates do
  json.array! @templates do |template|
    json.template do
      json.partial! 'template', template: template
    end
  end
end
