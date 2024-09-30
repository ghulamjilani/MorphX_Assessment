# frozen_string_literal: true

envelope json do
  json.mention_suggestions do
    json.array! @mention_suggestions do |user|
      json.user do
        json.extract! user, :id, :public_display_name, :slug # , :avatar_url
        json.relative_path spa_user_path(user.slug)
      end
    end
  end
end
