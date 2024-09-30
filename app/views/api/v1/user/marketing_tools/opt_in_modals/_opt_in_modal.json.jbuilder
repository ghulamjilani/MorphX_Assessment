# frozen_string_literal: true

json.extract! opt_in_modal, :id, :title, :description, :active, :trigger_time, :views_count, :submits_count, :created_at, :updated_at, :channel_uuid
# json.channel do
#   json.partial! 'api/v1/user/channels/channel_short', channel: opt_in_modal.channel
# end
json.system_template do
  json.partial! 'api/v1/user/page_builder/system_templates/system_template', system_template: opt_in_modal.system_template
end
