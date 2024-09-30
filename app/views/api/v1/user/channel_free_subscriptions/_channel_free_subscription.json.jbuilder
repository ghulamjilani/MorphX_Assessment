# frozen_string_literal: true

json.id                         free_subscription.id
json.free_plan_id               free_subscription.free_plan_id
json.replays                    free_subscription.replays
json.uploads                    free_subscription.uploads
json.livestreams                free_subscription.livestreams
json.interactives               free_subscription.interactives
json.documents                  free_subscription.documents
json.im_channel_conversation    free_subscription.im_channel_conversation
json.duration_in_months         free_subscription.duration_in_months
json.created_at                 free_subscription.created_at
json.starts_at                  free_subscription.starts_at
json.end_at                     free_subscription.end_at
json.stopped_at                 free_subscription.stopped_at

json.channel do
  json.extract! free_subscription.channel, :id, :title, :relative_path, :logo_url
  json.cover_url free_subscription.channel.image_url
end
