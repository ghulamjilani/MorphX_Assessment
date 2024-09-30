# frozen_string_literal: true

envelope json, (@status || 200), (@studio.pretty_errors if @studio.errors.present?) do
  json.studio do
    json.partial! 'studio', studio: @studio
  end
end
