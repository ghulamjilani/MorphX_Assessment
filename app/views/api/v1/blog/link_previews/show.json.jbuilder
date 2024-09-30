# frozen_string_literal: true

envelope json, (@status || 200), (@link_preview.pretty_errors if @link_preview.errors.present?) do
  json.link_preview do
    json.partial! 'link_preview', link_preview: @link_preview
  end
end
