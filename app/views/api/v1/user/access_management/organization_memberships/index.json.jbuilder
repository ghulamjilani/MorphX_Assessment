# frozen_string_literal: true

envelope json do
  json.organization_memberships do
    json.array! @organization_memberships do |organization_membership|
      json.organization_membership do
        json.partial! 'organization_membership', organization_membership: organization_membership

        json.groups_members do
          json.array! organization_membership.groups_members do |group_member|
            json.partial! 'groups_member', group_member: group_member

            json.channels do
              json.array! group_member.groups_members_channels do |gmc|
                json.partial! 'api/v1/public/channels/channel', model: gmc.channel
              end
            end
          end
        end

        json.user do
          json.partial! 'api/v1/public/users/user_short', model: organization_membership.user
          json.email organization_membership.user.email
        end
      end
    end
  end
end
