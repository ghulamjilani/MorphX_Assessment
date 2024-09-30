# frozen_string_literal: true

envelope json do
  json.link_previews do
    json.array! @link_previews do |link_preview|
      json.link_preview do
        json.partial! 'link_preview', link_preview: link_preview
      end
    end
  end
end
