# frozen_string_literal: true

json.cache! channel_invited_presentership, expires_in: 1.day do
  json.id                   channel_invited_presentership.id
  json.status               channel_invited_presentership.status
  json.channel_id           channel_invited_presentership.channel_id
  json.invitation_sent_at   channel_invited_presentership.invitation_sent_at
  json.created_at           channel_invited_presentership.created_at.utc.to_fs(:rfc3339)
  json.updated_at           channel_invited_presentership.updated_at.utc.to_fs(:rfc3339)
end
