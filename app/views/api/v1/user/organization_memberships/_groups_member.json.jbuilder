# frozen_string_literal: true

json.id             group_member.id
json.group_id       group_member.group.id
json.name           group_member.group.name
json.color          group_member.group.color
json.code           group_member.group.code
json.is_for_channel group_member.group.credentials.any?(&:is_for_channel?)
