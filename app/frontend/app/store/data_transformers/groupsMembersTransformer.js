import OrganizationMemberships from "@models/OrganizationMemberships"

export default {
    updateOrganizationMemberships({data, headers}) {
        let organizationMembership = OrganizationMemberships.find(data.response.group_member.organization_membership_id);
        let groups_members = JSON.parse(JSON.stringify(organizationMembership.groups_members))

        OrganizationMemberships.update({
            where: data.response.group_member.organization_membership_id,
            data: {
                groups_members: groups_members.map((gm) => {
                    if (gm.id === data.response.group_member.id) {
                        gm.channels = data.response.group_member.channels
                    }
                    return gm
                })
            }
        })

        return data
    },
}