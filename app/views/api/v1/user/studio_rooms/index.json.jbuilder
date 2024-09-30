# frozen_string_literal: true

envelope json do
  json.studio_rooms do
    json.array! @studio_rooms do |studio_room|
      json.studio_room do
        json.partial! 'studio_room', studio_room: studio_room
      end
    end
  end
end
