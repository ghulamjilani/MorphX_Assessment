# frozen_string_literal: true

envelope json do
  json.studios do
    json.array! @studios do |studio|
      json.studio do
        json.partial! 'studio', studio: studio
      end
    end
  end
end
