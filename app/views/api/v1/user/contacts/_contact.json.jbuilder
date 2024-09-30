# frozen_string_literal: true

json.cache! ['app/views/api/v1/user/contacts/_contact', contact], expires_in: 1.day do
  json.id                   contact.id
  json.status               contact.status
  json.email                contact.email
  json.name                 contact.name
  json.for_user_id          contact.for_user_id
  json.contact_user_id      contact.contact_user_id
  json.avatar_url           contact.avatar_url
end
