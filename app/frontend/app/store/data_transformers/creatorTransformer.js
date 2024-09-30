import Creator from "@models/Creator"
import eventHub from "@helpers/eventHub"

export default {
    search({data, headers, without_create}) {
        eventHub.$emit('searchResponse', {data: data, type: 'search'})
        let formatedCreators = []
        data.response.users.forEach((item) => {
            formatedCreators.push({
                name: item.user.public_display_name,
                value: item.user.public_display_name.replace(' ', ''),
                type: 'Creator',
                ...item.user
            })
        })
        if (!without_create) {
            Creator.create({data: formatedCreators})
        } else {
            Creator.insertOrUpdate({data: formatedCreators})
        }

        return formatedCreators
    }
}