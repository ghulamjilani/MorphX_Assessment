export default {
    fetch({data, headers}) {
        let groups = []
        data.response?.groups?.forEach(item => {
            let group = item
            group.id = item.id
            group.code = item.code
            group.description = item.description
            group.enabled = item.enabled
            group.name = item.name
            group.credentials = item.credentials
            group.system = item.system
            group.created_at = item.created_at
            group.updated_at = item.updated_at
            groups.push(group)
        });

        return groups
    },
    create({data, headers}) {
        let item = data?.response?.group
        let group = item
        group.id = item.id
        group.code = item.code
        group.description = item.description
        group.enabled = item.enabled
        group.name = item.name
        group.credentials = item.credentials
        group.system = item.system
        group.color = item.color
        group.created_at = item.created_at
        group.updated_at = item.updated_at

        return group
    }
}