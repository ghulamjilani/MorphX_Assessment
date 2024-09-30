# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.extract!             model, :id, :title, :description, :status, :presenter_id,
                            :organization_id, :category_id, :tagline, :short_url,
                            :logo_url, :image_gallery_url, :tag_list, :display_empty_blog,
                            :live_guide_is_visible, :im_conversation_enabled, :show_documents
  json.language             model.organizer&.language
  json.relative_path        spa_channel_path(model.slug)
  json.past_sessions_count  model.past_sessions_count
  json.cover_url            model.image_url
  json.category_name        model.category&.name
  begin
    json.gallery model.materials
  rescue StandardError
    json.gallery []
  end
  json.listed_at            model.listed_at&.to_fs(:rfc3339)
  json.created_at           model.created_at.utc.to_fs(:rfc3339)
  json.updated_at           model.updated_at.utc.to_fs(:rfc3339)
  json.is_default           model.is_default
end
