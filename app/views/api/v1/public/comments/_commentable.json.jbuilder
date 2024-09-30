# frozen_string_literal: true

json.cache! commentable, expires_in: 1.day do
  json.id                   commentable.id
  json.always_present_title commentable.try(:always_present_title)
  json.absolute_path        commentable.try(:records)&.first&.absolute_path || commentable.try(:absolute_path)
  case commentable
  when Session
    json.image_url(commentable.records.first&.poster_url || commentable.medium_cover_url)
  when Recording
    json.image_url commentable.poster_url
  end
end
