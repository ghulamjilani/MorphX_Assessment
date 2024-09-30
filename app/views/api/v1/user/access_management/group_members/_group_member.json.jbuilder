# frozen_string_literal: true

json.extract! group_member, :id, :access_management_group_id, :organization_membership_id
json.role_id group_member.group.id
json.name group_member.group.name
json.color group_member.group.color
json.channels do
  json.array! group_member.groups_members_channels do |gmc|
    json.id gmc.channel_id
    json.title gmc.channel.title
  end
end
