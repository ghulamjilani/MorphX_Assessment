# frozen_string_literal: true

json.cache! [participant], expires_in: 1.day do
  json.extract! participant, :id, :public_display_name, :relative_path, :avatar_url
end
