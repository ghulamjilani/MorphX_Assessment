# frozen_string_literal: true

json.cache! social_link, expires_in: 1.day do
  json.extract! social_link, :id, :provider
  json.url      social_link.link_as_url
end
