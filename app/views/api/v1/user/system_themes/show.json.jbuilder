# frozen_string_literal: true

envelope json, (@status || 200), (@theme.pretty_errors if @theme.errors.present?) do
  json.theme do
    json.partial! 'extended_theme', theme: @theme
  end
end
