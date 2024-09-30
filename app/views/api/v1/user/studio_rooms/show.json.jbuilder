# frozen_string_literal: true

envelope json, (@status || 200), (@studio_room.pretty_errors if @studio_room.errors.present?) do
  json.studio_room do
    json.partial! 'studio_room', studio_room: @studio_room
  end
end
