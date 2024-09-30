# frozen_string_literal: true

envelope json do
  json.system_themes do
    json.array! @system_themes do |theme|
      json.partial! 'theme', model: theme
    end
  end
end
