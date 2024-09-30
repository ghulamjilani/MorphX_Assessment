# frozen_string_literal: true

envelope json, (@status || 200), (@image.pretty_errors if @image.errors.present?) do
  json.image do
    json.partial! 'image', image: @image
  end
end
