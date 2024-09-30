export default {
    fetch({data, headers}) {
        let organization_memberships = []
        data.response?.organization_memberships?.forEach(item => {
            let membership = item.organization_membership
            membership.id = item.organization_membership.id
            membership.organization_id = item.organization_membership.organization_id
            membership.groups_members = item.organization_membership.groups_members
            membership.status = item.organization_membership.status
            membership.user = item.organization_membership.user
            membership.count = data.count
            organization_memberships.push(membership)
        });

        return organization_memberships
    },
    create({data, headers}) {
        let item = data.response?.organization_membership
        let membership = item
        membership.id = item.id
        membership.organization_id = item.organization_id
        membership.groups_members = item.groups_members
        membership.status = item.status
        membership.user = item.user

        return membership
    }
}
