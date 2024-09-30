# frozen_string_literal: true

envelope json, (@status || 200), (@session.pretty_errors if @session&.errors.present?) do
  if @session.present?
    json.session do
      json.extract! @session, :id, :title, :relative_path, :service_type
      json.room_id @session.room_id
      json.organizer_id @session.organizer.id

      json.start_at @start_at&.utc&.to_fs(:rfc3339)
      json.presenter @presenter
      json.type @type

      json.existence_path @existence_path
      json.show_page_paths @show_page_paths
    end
  end
end
