# frozen_string_literal: true

json.id                   free_subscription.id
json.created_at           free_subscription.created_at.utc.to_fs(:rfc3339)
json.starts_at            free_subscription.starts_at&.utc&.to_fs(:rfc3339)
json.start_at             free_subscription.start_at&.utc&.to_fs(:rfc3339)
json.end_at               free_subscription.end_at&.utc&.to_fs(:rfc3339)
json.stopped_at           free_subscription.stopped_at&.utc&.to_fs(:rfc3339)
json.duration_in_months   free_subscription.duration_in_months

json.user do
  json.partial! 'api/v1/user/free_subscriptions/user', user: free_subscription.user
end

json.channel do
  json.partial! 'api/v1/user/free_subscriptions/channel', channel: free_subscription.channel
end
