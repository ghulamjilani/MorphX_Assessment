# frozen_string_literal: true

envelope json do
  json.themes do
    json.array! @themes do |theme|
      json.theme do
        json.partial! 'theme', theme: theme
      end
    end
  end
end
