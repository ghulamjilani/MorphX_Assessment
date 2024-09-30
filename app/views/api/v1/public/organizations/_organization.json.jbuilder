# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.extract! model, :id, :name, :website_url, :relative_path, :short_url, :tagline, :description,
                :slug, :logo_url, :poster_url, :count_user_followers,
                :custom_logo_url, :custom_css

  json.logo_link            model.logo_link(current_user)
  json.created_at           model.created_at.utc.to_fs(:rfc3339)
  json.updated_at           model.updated_at.utc.to_fs(:rfc3339)
end

json.social_links do
  json.array! model.social_links do |social_link|
    json.partial! 'api/v1/public/social_links/social_link', social_link: social_link
  end
end
