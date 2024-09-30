# frozen_string_literal: true

envelope json, (@status || 200) do
  if @zoom_user.present?
    json.zoom_user do
      json.uid @zoom_user[:id]
      json.first_name @zoom_user[:first_name]
      json.last_name @zoom_user[:last_name]
      json.email @zoom_user[:email]
      json.type @zoom_user[:type]
      json.timezone @zoom_user[:timezone]
      json.account_id @zoom_user[:account_id]
      json.role_id @zoom_user[:role_id]
    end
  end
end
